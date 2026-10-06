package com.umc.javaStudy.repository;

import lombok.RequiredArgsConstructor;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Repository;

@Repository
@RequiredArgsConstructor
public class RentalRepository {

    private final JdbcTemplate jdbcTemplate;

    public void save(Long userId, Long bookId) {
        String sql = """
                INSERT INTO rental (user_id, book_id, rented_at, due_at)
                VALUES (?, ?, NOW(), DATE_ADD(NOW(), INTERVAL 7 DAY))
                """;

        jdbcTemplate.update(sql, userId, bookId);
    }

    public int returnRental(Long rentalId) {
        String sql = """
            UPDATE rental
            SET returned_at = NOW()
            WHERE rental_id = ?
            """;

        return jdbcTemplate.update(sql, rentalId);
    }
}