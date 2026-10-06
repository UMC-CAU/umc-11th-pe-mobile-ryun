package com.umc.javaStudy.service;

import com.umc.javaStudy.repository.RentalRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

@Service
@RequiredArgsConstructor
public class RentalService {

    private final RentalRepository rentalRepository;

    public void createRental(Long userId, Long bookId) {
        rentalRepository.save(userId, bookId);
    }

    public int returnRental(Long rentalId) {
        return rentalRepository.returnRental(rentalId);
    }
}