-- 기존 MySQL DB에서 수동으로 1회 실행합니다. ddl-auto: validate는 이 변경을 적용하지 않습니다.
-- 먼저 아래 SELECT만 실행합니다. 결과가 있다면 중복 데이터 처리 방침을 정한 후 ALTER를 실행하세요.
-- 현재 테이블의 collation 기준으로 중복을 판단합니다. 데이터는 자동 삭제하지 않습니다.
SELECT title, COUNT(*) AS duplicate_count
FROM book
GROUP BY title
HAVING COUNT(*) > 1;

-- 이미 적용된 경우에는 재실행하지 않습니다.
ALTER TABLE book ADD CONSTRAINT uk_book_title UNIQUE (title);

-- 적용 확인: Non_unique가 0이고 Column_name이 title이어야 합니다.
SHOW INDEX FROM book WHERE Key_name = 'uk_book_title';
