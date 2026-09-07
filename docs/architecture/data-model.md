# Sơ đồ dữ liệu mức domain

Sơ đồ tập trung vào các quan hệ quan trọng cho phần trình bày. Tên field chi tiết nằm trong `BackEnd/model/`.

```mermaid
erDiagram
    USER ||--o{ LESSON_PROGRESS : studies
    USER ||--o{ EXERCISE_RESULT : submits
    USER ||--o{ SRS_PROGRESS : reviews
    USER ||--o{ NOTEBOOK : writes
    USER ||--o{ USER_ACHIEVEMENT : earns
    USER ||--|| USER_STREAK : owns
    USER ||--o{ REPORT : creates
    USER ||--o{ TRANSACTION : requests
    USER }o--o{ STUDY_GROUP : joins

    LESSON ||--o{ VOCABULARY : contains
    LESSON ||--o{ KANJI : contains
    LESSON ||--o{ GRAMMAR : contains
    LESSON ||--o{ EXERCISE : has
    LESSON ||--o{ LESSON_PROGRESS : tracked_by
    EXERCISE ||--o{ EXERCISE_RESULT : produces
    ACHIEVEMENT ||--o{ USER_ACHIEVEMENT : awarded_as
    STUDY_GROUP ||--o{ GROUP_MESSAGE : contains

    USER {
      ObjectId _id PK
      string Email
      string MatKhauHash
      string VaiTro
      string TrangThai
    }
    LESSON {
      ObjectId _id PK
      string title
      string level
      number order
    }
    VOCABULARY {
      ObjectId _id PK
      ObjectId lesson FK
      string word
      string hiragana
      string meaning
    }
    KANJI {
      ObjectId _id PK
      ObjectId lessonId FK
      string character
      string meaning
    }
    GRAMMAR {
      ObjectId _id PK
      ObjectId lesson_id FK
      string title
      string structure
    }
    EXERCISE {
      ObjectId _id PK
      ObjectId lesson_id FK
      array questions
      number pass_score
    }
    EXERCISE_RESULT {
      ObjectId _id PK
      ObjectId user_id FK
      ObjectId exercise_id FK
      number score
    }
```

MongoDB không áp dụng foreign key ở tầng database; controller và Mongoose validation chịu trách nhiệm kiểm tra tham chiếu. Các relation phục vụ truy vấn thường có index trong schema.
