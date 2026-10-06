package com.umc.javaStudy.controller;

import com.umc.javaStudy.service.RentalService;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

@RestController
@RequestMapping("/rentals")
@RequiredArgsConstructor
public class RentalController {

    private final RentalService rentalService;

    @PostMapping
    public String createRental(@RequestBody Map<String, Object> body) {
        Long userId = ((Number) body.get("userId")).longValue();
        Long bookId = ((Number) body.get("bookId")).longValue();

        rentalService.createRental(userId, bookId);

        return "도서 대여 기록이 생성되었습니다!";
    }

    @PatchMapping("/{rentalId}/return")
    public String returnRental(@PathVariable Long rentalId) {
        int updatedRows = rentalService.returnRental(rentalId);

        if (updatedRows == 0) {
            return "존재하지 않는 대여 기록입니다.";
        }

        return "도서가 반납 처리되었습니다!";
    }
}