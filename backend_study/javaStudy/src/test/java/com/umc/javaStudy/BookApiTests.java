package com.umc.javaStudy;

import com.fasterxml.jackson.databind.ObjectMapper;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.web.servlet.MockMvc;

import java.util.Map;
import java.util.List;
import java.util.concurrent.Callable;
import java.util.concurrent.Executors;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;
import org.springframework.dao.DataIntegrityViolationException;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles("test")
class BookApiTests {
    @Autowired MockMvc mvc;
    @Autowired JdbcTemplate jdbc;
    @Autowired ObjectMapper json;

    @BeforeEach
    void seed() {
        jdbc.update("DELETE FROM book");
        jdbc.update("DELETE FROM category");
        jdbc.update("INSERT INTO category(category_id, name) VALUES (1, '문학'), (2, '과학')");
        jdbc.update("INSERT INTO book(book_id, category_id, title, description, is_available) "
                + "VALUES (10, 1, '첫 도서', '설명', 1), (20, 2, '최신 도서', NULL, 0)");
    }

    @Test
    void listsAllBooksNewestFirstWithCategoryAndDtoFields() throws Exception {
        mvc.perform(get("/books"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.length()").value(2))
                .andExpect(jsonPath("$[0].bookId").value(20))
                .andExpect(jsonPath("$[0].title").value("최신 도서"))
                .andExpect(jsonPath("$[0].categoryName").value("과학"))
                .andExpect(jsonPath("$[0].isAvailable").value(false))
                .andExpect(jsonPath("$[0].book_id").doesNotExist())
                .andExpect(jsonPath("$[0].category").doesNotExist());
    }

    @Test
    void createsAndPersistsBookWithOptionalDescription() throws Exception {
        String result = mvc.perform(post("/books").contentType("application/json")
                        .content("{\"categoryId\":1,\"title\":\"JPA 입문\"}"))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.bookId").isNumber())
                .andExpect(jsonPath("$.title").value("JPA 입문"))
                .andExpect(jsonPath("$.categoryName").value("문학"))
                .andExpect(jsonPath("$.isAvailable").value(true))
                .andReturn().getResponse().getContentAsString();
        long id = json.readTree(result).get("bookId").asLong();
        assertEquals("JPA 입문", jdbc.queryForObject("SELECT title FROM book WHERE book_id = ?", String.class, id));
        assertEquals(3, countBooks());
    }

    @Test
    void rejectsMissingCategoryWithoutSaving() throws Exception {
        mvc.perform(post("/books").contentType("application/json")
                        .content("{\"categoryId\":999999,\"title\":\"오류 도서\"}"))
                .andExpect(status().isNotFound())
                .andExpect(jsonPath("$.detail").value("존재하지 않는 카테고리입니다."));
        assertEquals(2, countBooks());
    }

    @Test
    void rejectsInvalidRequestsWithoutSaving() throws Exception {
        String[] invalid = {
                "{\"title\":\"제목\"}",
                "{\"categoryId\":1,\"title\":\"   \"}",
                "{\"categoryId\":1,\"title\":\"\"}",
                "{\"categoryId\":1}",
                "{\"categoryId\":\"abc\",\"title\":\"제목\"}",
                json.writeValueAsString(Map.of("categoryId", 1, "title", "가".repeat(101)))
        };
        for (String body : invalid) {
            mvc.perform(post("/books").contentType("application/json").content(body))
                    .andExpect(status().isBadRequest())
                    .andExpect(jsonPath("$.status").value(400));
        }
        assertEquals(2, countBooks());
    }

    @Test
    void acceptsTitleAtMaximumLengthAndDescription() throws Exception {
        mvc.perform(post("/books").contentType("application/json")
                        .content(json.writeValueAsString(Map.of(
                                "categoryId", 1, "title", "가".repeat(100), "description", "설명"))))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.description").value("설명"));
    }

    @Test
    void keepsCategoryFilterWorking() throws Exception {
        mvc.perform(get("/books/category/1"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.length()").value(1))
                .andExpect(jsonPath("$[0].bookId").value(10));
    }

    @Test
    void returnsEmptyListWhenNoBooksExist() throws Exception {
        jdbc.update("DELETE FROM book");
        mvc.perform(get("/books"))
                .andExpect(status().isOk())
                .andExpect(content().json("[]"));
    }

    @Test
    void searchesTitlesAndPreservesOrderAndCategoryNames() throws Exception {
        mvc.perform(get("/books").param("keyword", "도서"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.length()").value(2))
                .andExpect(jsonPath("$[0].bookId").value(20))
                .andExpect(jsonPath("$[0].categoryName").value("과학"));
        mvc.perform(get("/books").param("keyword", " 첫 "))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.length()").value(1))
                .andExpect(jsonPath("$[0].bookId").value(10));
    }

    @Test
    void missingSearchResultIsAnEmptyList() throws Exception {
        mvc.perform(get("/books").param("keyword", "없는제목"))
                .andExpect(status().isOk()).andExpect(content().json("[]"));
    }

    @Test
    void blankKeywordReturnsAllBooks() throws Exception {
        mvc.perform(get("/books").param("keyword", "   "))
                .andExpect(status().isOk()).andExpect(jsonPath("$.length()").value(2));
    }

    @Test
    void searchTreatsSqlWildcardsAsLiteralCharacters() throws Exception {
        jdbc.update("INSERT INTO book(category_id, title, is_available) VALUES (1, '100%_도서', 1)");
        mvc.perform(get("/books").param("keyword", "%_"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.length()").value(1))
                .andExpect(jsonPath("$[0].title").value("100%_도서"));
    }

    @Test
    void duplicateTitleReturns409WithoutSaving() throws Exception {
        mvc.perform(post("/books").contentType("application/json")
                        .content("{\"categoryId\":2,\"title\":\"첫 도서\"}"))
                .andExpect(status().isConflict())
                .andExpect(jsonPath("$.detail").value("이미 등록된 도서 제목입니다."));
        assertEquals(2, countBooks());
    }

    @Test
    void databaseItselfRejectsDuplicateTitles() {
        assertThrows(DataIntegrityViolationException.class, () -> jdbc.update(
                "INSERT INTO book(category_id, title, is_available) VALUES (2, '첫 도서', 1)"));
        assertEquals(2, countBooks());
    }

    @Test
    void concurrentDuplicateRequestsSaveOnlyOneBook() throws Exception {
        Callable<Integer> create = () -> mvc.perform(post("/books").contentType("application/json")
                        .content("{\"categoryId\":1,\"title\":\"동시 등록 도서\"}"))
                .andReturn().getResponse().getStatus();
        try (var executor = Executors.newFixedThreadPool(2)) {
            var results = executor.invokeAll(List.of(create, create));
            var statuses = List.of(results.get(0).get(), results.get(1).get()).stream().sorted().toList();
            assertEquals(List.of(201, 409), statuses);
        }
        assertEquals(3, countBooks());
    }

    private int countBooks() {
        return jdbc.queryForObject("SELECT COUNT(*) FROM book", Integer.class);
    }
}
