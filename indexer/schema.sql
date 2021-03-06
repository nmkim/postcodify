
-- 이미 존재하는 테이블과 프로시저를 삭제한다.

DROP TABLE IF EXISTS postcode_addresses;
DROP TABLE IF EXISTS postcode_keywords_juso;
DROP TABLE IF EXISTS postcode_keywords_jibeon;
DROP TABLE IF EXISTS postcode_keywords_building;
DROP TABLE IF EXISTS postcode_keywords_pobox;
DROP TABLE IF EXISTS postcode_metadata;

DROP PROCEDURE IF EXISTS postcode_search_juso;
DROP PROCEDURE IF EXISTS postcode_search_juso_in_area;
DROP PROCEDURE IF EXISTS postcode_search_jibeon;
DROP PROCEDURE IF EXISTS postcode_search_jibeon_in_area;
DROP PROCEDURE IF EXISTS postcode_search_building;
DROP PROCEDURE IF EXISTS postcode_search_building_in_area;
DROP PROCEDURE IF EXISTS postcode_search_building_with_dongri;
DROP PROCEDURE IF EXISTS postcode_search_building_with_dongri_in_area;
DROP PROCEDURE IF EXISTS postcode_search_pobox;
DROP PROCEDURE IF EXISTS postcode_search_pobox_in_area;

-- 주소 정보를 저장하는 메인 테이블.

CREATE TABLE postcode_addresses (
    id NUMERIC(25) PRIMARY KEY,                         -- 관리번호 (PK)
    postcode5 CHAR(5),                                  -- 기초구역번호
    postcode6 CHAR(6),                                  -- 우편번호
    road_id NUMERIC(12),                                -- 도로번호
    road_section CHAR(2),                               -- 도로구간번호
    road_name VARCHAR(80),                              -- 도로명
    num_major SMALLINT(5) UNSIGNED,                     -- 도로명주소 주번호
    num_minor SMALLINT(5) UNSIGNED,                     -- 도로명주소 부번호
    is_basement TINYINT(1) DEFAULT 0,                   -- 지하여부
    sido VARCHAR(20),                                   -- 시/도
    sigungu VARCHAR(20),                                -- 시/군/자치구
    ilbangu VARCHAR(20),                                -- 일반구
    eupmyeon VARCHAR(20),                               -- 읍/면
    dongri VARCHAR(20),                                 -- 동/리
    jibeon VARCHAR(10),                                 -- 지번
    building_name VARCHAR(40),                          -- 공동주택명
    english_address VARCHAR(300),                       -- 영문 주소
    other_addresses VARCHAR(600),                       -- 관련주소목록
    updated NUMERIC(8)                                  -- 업데이트 여부
) ENGINE = InnoDB CHARACTER SET = utf8 COLLATE = utf8_general_ci;

-- 도로명주소 검색을 위한 키워드 테이블.

CREATE TABLE postcode_keywords_juso (
    seq INT UNSIGNED PRIMARY KEY AUTO_INCREMENT,        -- PK
    address_id NUMERIC(25) NOT NULL,                    -- 관리번호 (FK)
    keyword_crc32 INT(10) UNSIGNED,                     -- 도로명의 CRC32 값
    num_major SMALLINT(5) UNSIGNED,                     -- 도로명주소 주번호
    num_minor SMALLINT(5) UNSIGNED                      -- 도로명주소 부번호
) ENGINE = InnoDB CHARACTER SET = utf8 COLLATE = utf8_general_ci;

-- 지번 검색을 위한 키워드 테이블.

CREATE TABLE postcode_keywords_jibeon (
    seq INT UNSIGNED PRIMARY KEY AUTO_INCREMENT,        -- PK
    address_id NUMERIC(25) NOT NULL,                    -- 관리번호 (FK)
    keyword_crc32 INT(10) UNSIGNED,                     -- 동/리명의 CRC32 값
    num_major SMALLINT(5) UNSIGNED,                     -- 지번 주번호
    num_minor SMALLINT(5) UNSIGNED                      -- 지번 부번호
) ENGINE = InnoDB CHARACTER SET = utf8 COLLATE = utf8_general_ci;

-- 건물명 검색을 위한 키워드 테이블.

CREATE TABLE postcode_keywords_building (
    seq INT UNSIGNED PRIMARY KEY AUTO_INCREMENT,        -- PK
    address_id NUMERIC(25) NOT NULL,                    -- 관리번호 (FK)
    keyword VARCHAR(40)                                 -- 건물명
) ENGINE = InnoDB CHARACTER SET = utf8 COLLATE = utf8_general_ci;

-- 사서함 검색을 위한 키워드 테이블.

CREATE TABLE postcode_keywords_pobox (
    seq INT UNSIGNED PRIMARY KEY AUTO_INCREMENT,        -- PK
    address_id NUMERIC(25) NOT NULL,                    -- 관리번호 (FK)
    keyword VARCHAR(40),                                -- 사서함명 검색어
    range_start_major SMALLINT(5) UNSIGNED,             -- 시작 주번호
    range_start_minor SMALLINT(5) UNSIGNED,             -- 시작 부번호
    range_end_major SMALLINT(5) UNSIGNED,               -- 끝 주번호
    range_end_minor SMALLINT(5) UNSIGNED                -- 끝 부번호
) ENGINE = InnoDB CHARACTER SET = utf8 COLLATE = utf8_general_ci;

-- 각종 설정을 저장하는 테이블.

CREATE TABLE postcode_metadata (
    k VARCHAR(20) PRIMARY KEY,                          -- 설정 키
    v VARCHAR(40)                                       -- 설정 값
) ENGINE = InnoDB CHARACTER SET = utf8 COLLATE = utf8_general_ci;

-- 도로명주소 검색 (단순) 프로시저.

CREATE PROCEDURE postcode_search_juso(IN keyword_crc32 INT UNSIGNED,
    IN num1 SMALLINT UNSIGNED, IN num2 SMALLINT UNSIGNED)
BEGIN
    SELECT DISTINCT pa.* FROM postcode_addresses AS pa
    INNER JOIN postcode_keywords_juso AS pk ON pa.id = pk.address_id
    WHERE pk.keyword_crc32 = keyword_crc32
        AND (num1 IS NULL OR pk.num_major = num1)
        AND (num2 IS NULL OR pk.num_minor = num2)
    ORDER BY pa.sido, pa.sigungu, pa.road_name, pa.num_major, pa.num_minor
    LIMIT 100;
END;

-- 도로명주소 검색 (지역 제한) 프로시저.

CREATE PROCEDURE postcode_search_juso_in_area(IN keyword_crc32 INT UNSIGNED,
    IN num1 SMALLINT UNSIGNED, IN num2 SMALLINT UNSIGNED,
    IN area1 VARCHAR(20), IN area2 VARCHAR(20),
    IN area3 VARCHAR(20), IN area4 VARCHAR(20))
BEGIN
    SELECT DISTINCT pa.* FROM postcode_addresses AS pa
    INNER JOIN postcode_keywords_juso AS pk ON pa.id = pk.address_id
    WHERE pk.keyword_crc32 = keyword_crc32
        AND (num1 IS NULL OR pk.num_major = num1)
        AND (num2 IS NULL OR pk.num_minor = num2)
        AND (area1 IS NULL OR pa.sido = area1)
        AND (area2 IS NULL OR pa.sigungu = area2)
        AND (area3 IS NULL OR pa.ilbangu = area3)
        AND (area4 IS NULL OR pa.eupmyeon = area4)
    ORDER BY pa.sido, pa.sigungu, pa.road_name, pa.num_major, pa.num_minor
    LIMIT 100;
END;

-- 지번 검색 (단순) 프로시저.

CREATE PROCEDURE postcode_search_jibeon(IN keyword_crc32 INT UNSIGNED,
    IN num1 SMALLINT UNSIGNED, IN num2 SMALLINT UNSIGNED)
BEGIN
    SELECT DISTINCT pa.* FROM postcode_addresses AS pa
    INNER JOIN postcode_keywords_jibeon AS pk ON pa.id = pk.address_id
    WHERE pk.keyword_crc32 = keyword_crc32
        AND (num1 IS NULL OR pk.num_major = num1)
        AND (num2 IS NULL OR pk.num_minor = num2)
    ORDER BY pa.sido, pa.sigungu, pa.road_name, pa.num_major, pa.num_minor
    LIMIT 100;
END;

-- 지번 검색 (지역 제한) 프로시저.

CREATE PROCEDURE postcode_search_jibeon_in_area(IN keyword_crc32 INT UNSIGNED,
    IN num1 SMALLINT UNSIGNED, IN num2 SMALLINT UNSIGNED,
    IN area1 VARCHAR(20), IN area2 VARCHAR(20),
    IN area3 VARCHAR(20), IN area4 VARCHAR(20))
BEGIN
    SELECT DISTINCT pa.* FROM postcode_addresses AS pa
    INNER JOIN postcode_keywords_jibeon AS pk ON pa.id = pk.address_id
    WHERE pk.keyword_crc32 = keyword_crc32
        AND (num1 IS NULL OR pk.num_major = num1)
        AND (num2 IS NULL OR pk.num_minor = num2)
        AND (area1 IS NULL OR pa.sido = area1)
        AND (area2 IS NULL OR pa.sigungu = area2)
        AND (area3 IS NULL OR pa.ilbangu = area3)
        AND (area4 IS NULL OR pa.eupmyeon = area4)
    ORDER BY pa.sido, pa.sigungu, pa.road_name, pa.num_major, pa.num_minor
    LIMIT 100;
END;

-- 건물명 검색 (단순) 프로시저.

CREATE PROCEDURE postcode_search_building(IN keyword VARCHAR(80))
BEGIN
    SELECT DISTINCT pa.* FROM postcode_addresses AS pa
    INNER JOIN postcode_keywords_building AS pk ON pa.id = pk.address_id
    WHERE pk.keyword LIKE CONCAT('%', keyword, '%')
    ORDER BY pa.sido, pa.sigungu, pa.road_name, pa.num_major, pa.num_minor
    LIMIT 100;
END;

-- 건물명 검색 (지역 제한) 프로시저.

CREATE PROCEDURE postcode_search_building_in_area(IN keyword VARCHAR(80),
    IN area1 VARCHAR(20), IN area2 VARCHAR(20),
    IN area3 VARCHAR(20), IN area4 VARCHAR(20))
BEGIN
    SELECT DISTINCT pa.* FROM postcode_addresses AS pa
    INNER JOIN postcode_keywords_building AS pk ON pa.id = pk.address_id
    WHERE pk.keyword LIKE CONCAT('%', keyword, '%')
        AND (area1 IS NULL OR pa.sido = area1)
        AND (area2 IS NULL OR pa.sigungu = area2)
        AND (area3 IS NULL OR pa.ilbangu = area3)
        AND (area4 IS NULL OR pa.eupmyeon = area4)
    ORDER BY pa.sido, pa.sigungu, pa.road_name, pa.num_major, pa.num_minor
    LIMIT 100;
END;

-- 건물명 + 동/리 검색 (단순) 프로시저.

CREATE PROCEDURE postcode_search_building_with_dongri (IN keyword VARCHAR(80),
    IN dongri_crc32 INT UNSIGNED)
BEGIN
    SELECT DISTINCT pa.* FROM postcode_addresses AS pa
    INNER JOIN postcode_keywords_building AS pkb ON pa.id = pkb.address_id
    INNER JOIN postcode_keywords_jibeon AS pkj ON pa.id = pkj.address_id
    WHERE pkb.keyword LIKE CONCAT('%', keyword, '%')
        AND pkj.keyword_crc32 = dongri_crc32
    ORDER BY pa.sido, pa.sigungu, pa.road_name, pa.num_major, pa.num_minor
    LIMIT 100;
END;

-- 건물명 + 동/리 검색 (지역 제한) 프로시저.

CREATE PROCEDURE postcode_search_building_with_dongri_in_area(IN keyword VARCHAR(80),
    IN dongri_crc32 INT UNSIGNED,
    IN area1 VARCHAR(20), IN area2 VARCHAR(20),
    IN area3 VARCHAR(20), IN area4 VARCHAR(20))
BEGIN
    SELECT DISTINCT pa.* FROM postcode_addresses AS pa
    INNER JOIN postcode_keywords_building AS pkb ON pa.id = pkb.address_id
    INNER JOIN postcode_keywords_jibeon AS pkj ON pa.id = pkj.address_id
    WHERE pkb.keyword LIKE CONCAT('%', keyword, '%')
        AND pkj.keyword_crc32 = dongri_crc32
        AND (area1 IS NULL OR pa.sido = area1)
        AND (area2 IS NULL OR pa.sigungu = area2)
        AND (area3 IS NULL OR pa.ilbangu = area3)
        AND (area4 IS NULL OR pa.eupmyeon = area4)
    ORDER BY pa.sido, pa.sigungu, pa.road_name, pa.num_major, pa.num_minor
    LIMIT 100;
END;

-- 사서함 검색 (단순) 프로시저.

CREATE PROCEDURE postcode_search_pobox(IN keyword VARCHAR(80),
    IN num1 SMALLINT UNSIGNED, IN num2 SMALLINT UNSIGNED)
BEGIN
    SELECT DISTINCT pa.* FROM postcode_addresses AS pa
    INNER JOIN postcode_keywords_pobox AS pk ON pa.id = pk.address_id
    WHERE pk.keyword LIKE CONCAT('%', keyword, '%')
        AND (num1 IS NULL OR num1 BETWEEN pk.range_start_major AND pk.range_end_major)
        AND (num2 IS NULL OR num2 BETWEEN pk.range_start_minor AND pk.range_end_minor)
    ORDER BY pa.sido, pa.sigungu, pa.road_name, pa.num_major, pa.num_minor
    LIMIT 100;
END;

-- 사서함 검색 (지역 제한) 프로시저.

CREATE PROCEDURE postcode_search_pobox_in_area(IN keyword VARCHAR(80),
    IN num1 SMALLINT UNSIGNED, IN num2 SMALLINT UNSIGNED,
    IN area1 VARCHAR(20), IN area2 VARCHAR(20),
    IN area3 VARCHAR(20), IN area4 VARCHAR(20))
BEGIN
    SELECT DISTINCT pa.* FROM postcode_addresses AS pa
    INNER JOIN postcode_keywords_pobox AS pk ON pa.id = pk.address_id
    WHERE pk.keyword LIKE CONCAT('%', keyword, '%')
        AND (num1 IS NULL OR num1 BETWEEN pk.range_start_major AND pk.range_end_major)
        AND (num2 IS NULL OR num2 BETWEEN pk.range_start_minor AND pk.range_end_minor)
        AND (area1 IS NULL OR pa.sido = area1)
        AND (area2 IS NULL OR pa.sigungu = area2)
        AND (area3 IS NULL OR pa.ilbangu = area3)
        AND (area4 IS NULL OR pa.eupmyeon = area4)
    ORDER BY pa.sido, pa.sigungu, pa.road_name, pa.num_major, pa.num_minor
    LIMIT 100;
END;
