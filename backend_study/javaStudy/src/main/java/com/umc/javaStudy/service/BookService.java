package com.umc.javaStudy.service;

import com.umc.javaStudy.dto.BookResponse;
import com.umc.javaStudy.dto.CreateBookRequest;
import com.umc.javaStudy.entity.Book;
import com.umc.javaStudy.entity.Category;
import com.umc.javaStudy.repository.BookRepository;
import com.umc.javaStudy.repository.CategoryRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.server.ResponseStatusException;
import java.util.List;

@Service
@RequiredArgsConstructor
public class BookService {
    private final BookRepository bookRepository;
    private final CategoryRepository categoryRepository;

    @Transactional(readOnly = true)
    public List<BookResponse> getBooks(String keyword) {
        List<Book> books = keyword == null || keyword.isBlank()
                ? bookRepository.findAllByOrderByBookIdDesc()
                : bookRepository.findByTitleContainingOrderByBookIdDesc(keyword.strip());
        return books.stream()
                .map(BookResponse::from)
                .toList();
    }

    @Transactional
    public BookResponse createBook(CreateBookRequest request) {
        Category category = categoryRepository.findById(request.categoryId())
                .orElseThrow(() -> new ResponseStatusException(
                        HttpStatus.NOT_FOUND, "존재하지 않는 카테고리입니다."));

        Book book = new Book(category, request.title(), request.description());
        // UNIQUE 위반을 이 요청 안에서 확인합니다. 동시 등록도 DB 제약으로 차단합니다.
        return BookResponse.from(bookRepository.saveAndFlush(book));
    }

    @Transactional(readOnly = true)
    public List<BookResponse> getBooksByCategory(Long categoryId) {
        return bookRepository.findByCategory_CategoryIdOrderByBookIdDesc(categoryId).stream()
                .map(BookResponse::from)
                .toList();
    }
}

