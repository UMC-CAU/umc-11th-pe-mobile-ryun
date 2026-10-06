package com.umc.javaStudy.repository;

import com.umc.javaStudy.entity.Category;
import org.springframework.data.jpa.repository.JpaRepository;

public interface CategoryRepository extends JpaRepository<Category, Long> {
}

