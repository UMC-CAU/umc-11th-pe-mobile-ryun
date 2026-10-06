package com.umc.javaStudy.repository;

import com.umc.javaStudy.entity.Book;
import org.springframework.data.jpa.repository.EntityGraph;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.List;

public interface BookRepository extends JpaRepository<Book, Long> {
    // 응답에 필요한 카테고리를 함께 조회해 도서별 추가 조회를 방지합니다.
    @EntityGraph(attributePaths = "category")
    List<Book> findAllByOrderByBookIdDesc();

    @EntityGraph(attributePaths = "category")
    List<Book> findByTitleContainingOrderByBookIdDesc(String keyword);

    @EntityGraph(attributePaths = "category")
    List<Book> findByCategory_CategoryIdOrderByBookIdDesc(Long categoryId);
}

