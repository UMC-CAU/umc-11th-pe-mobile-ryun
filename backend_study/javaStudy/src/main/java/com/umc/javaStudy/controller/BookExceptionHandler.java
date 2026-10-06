package com.umc.javaStudy.controller;

import org.hibernate.exception.ConstraintViolationException;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.http.HttpStatus;
import org.springframework.http.ProblemDetail;
import org.springframework.http.converter.HttpMessageNotReadableException;
import org.springframework.web.bind.MethodArgumentNotValidException;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;
import org.springframework.web.server.ResponseStatusException;

import java.util.Locale;
import java.util.Map;

@RestControllerAdvice(assignableTypes = BookController.class)
public class BookExceptionHandler {

    @ExceptionHandler(MethodArgumentNotValidException.class)
    public ProblemDetail handleValidation(MethodArgumentNotValidException exception) {
        ProblemDetail problem = ProblemDetail.forStatusAndDetail(
                HttpStatus.BAD_REQUEST, "요청 값을 확인해주세요.");
        problem.setProperty("errors", exception.getBindingResult().getFieldErrors().stream()
                .map(error -> Map.of("field", error.getField(),
                        "message", error.getDefaultMessage() == null
                                ? "유효하지 않은 값입니다." : error.getDefaultMessage()))
                .toList());
        return problem;
    }

    @ExceptionHandler(HttpMessageNotReadableException.class)
    public ProblemDetail handleUnreadableRequest(HttpMessageNotReadableException exception) {
        return ProblemDetail.forStatusAndDetail(
                HttpStatus.BAD_REQUEST, "JSON 형식과 필드 타입을 확인해주세요.");
    }

    @ExceptionHandler(ResponseStatusException.class)
    public ProblemDetail handleStatus(ResponseStatusException exception) {
        return ProblemDetail.forStatusAndDetail(exception.getStatusCode(), exception.getReason());
    }

    @ExceptionHandler(DataIntegrityViolationException.class)
    public ProblemDetail handleIntegrity(DataIntegrityViolationException exception) {
        for (Throwable cause = exception; cause != null; cause = cause.getCause()) {
            if (cause instanceof ConstraintViolationException violation) {
                String constraint = violation.getConstraintName();
                if (constraint != null && constraint.toLowerCase(Locale.ROOT).contains("uk_book_title")) {
                    return ProblemDetail.forStatusAndDetail(
                            HttpStatus.CONFLICT, "이미 등록된 도서 제목입니다.");
                }
            }
        }
        // 다른 무결성 오류를 제목 중복으로 잘못 안내하지 않습니다.
        return ProblemDetail.forStatusAndDetail(
                HttpStatus.CONFLICT, "데이터 제약 조건에 맞지 않아 저장할 수 없습니다.");
    }
}
