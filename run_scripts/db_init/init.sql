-- Table 1: Users (username, password, and user_id)
CREATE TABLE users (
	    user_id INT AUTO_INCREMENT PRIMARY KEY,  -- user_id will be the unique key
	    username VARCHAR(50) NOT NULL UNIQUE,    -- Unique username
	    password VARCHAR(255) NOT NULL           -- User password
);

-- Insert 20 users with username and password, user_id is auto-generated
INSERT INTO users (username, password) VALUES
('user1', 'password1'),
('user2', 'password2'),
('user3', 'password3'),
('user4', 'password4'),
('user5', 'password5'),
('user6', 'password6'),
('user7', 'password7'),
('user8', 'password8'),
('user9', 'password9'),
('user10', 'password10'),
('user11', 'password11'),
('user12', 'password12'),
('user13', 'password13'),
('user14', 'password14'),
('user15', 'password15'),
('user16', 'password16'),
('user17', 'password17'),
('user18', 'password18'),
('user19', 'password19'),
('user20', 'password20');

-- Table 2: Personal Info (personal details linked to each user)
CREATE TABLE personal_info (
	    user_id INT,                            -- Foreign key to users table
	    first_name VARCHAR(50),
	    last_name VARCHAR(50),
	    phone VARCHAR(20),
	    address VARCHAR(255),
	    age INT,
	    city VARCHAR(100),
	    FOREIGN KEY (user_id) REFERENCES users(user_id)  -- Linking to users table
);

-- Insert 20 records into personal_info
INSERT INTO personal_info (user_id, first_name, last_name, phone, address, age, city) VALUES
(1, 'Alice', 'Smith', '123-456-7890', '123 Maple St', 25, 'New York'),
(2, 'Bob', 'Jones', '987-654-3210', '456 Oak St', 30, 'Los Angeles'),
(3, 'Charlie', 'Brown', '555-555-5555', '789 Pine St', 22, 'Chicago'),
(4, 'David', 'White', '444-444-4444', '101 Birch St', 28, 'Houston'),
(5, 'Eve', 'Green', '333-333-3333', '202 Cedar St', 26, 'Phoenix'),
(6, 'Frank', 'Taylor', '222-222-2222', '303 Elm St', 35, 'Philadelphia'),
(7, 'Grace', 'Wilson', '111-111-1111', '404 Spruce St', 40, 'San Antonio'),
(8, 'Hank', 'Moore', '666-666-6666', '505 Ash St', 29, 'San Diego'),
(9, 'Ivy', 'Clark', '777-777-7777', '606 Redwood St', 32, 'Dallas'),
(10, 'Jack', 'King', '888-888-8888', '707 Palm St', 23, 'San Jose'),
(11, 'Kate', 'Scott', '999-999-9999', '808 Cedar Ave', 27, 'Austin'),
(12, 'Leo', 'Adams', '123-123-1234', '909 Pine St', 34, 'Jacksonville'),
(13, 'Mia', 'Nelson', '234-234-2345', '111 Maple Ave', 21, 'Fort Worth'),
(14, 'Nina', 'Roberts', '345-345-3456', '222 Oak Ave', 42, 'Columbus'),
(15, 'Oscar', 'Walker', '456-456-4567', '333 Birch Ave', 38, 'Charlotte'),
(16, 'Paul', 'Young', '567-567-5678', '444 Elm Ave', 36, 'San Francisco'),
(17, 'Quinn', 'Harris', '678-678-6789', '555 Spruce Ave', 31, 'Indianapolis'),
(18, 'Ray', 'Martin', '789-789-7890', '666 Palm Ave', 29, 'Seattle'),
(19, 'Sara', 'Allen', '890-890-8901', '777 Redwood Ave', 24, 'Denver'),
(20, 'Tom', 'Lewis', '901-901-9012', '888 Cedar Blvd', 28, 'Washington DC');

-- Table 3: Public Info (public details like Twitter, degree, etc.)
CREATE TABLE public_info (
	    user_id INT,                           -- Foreign key to users table
	    twitter_handle VARCHAR(50),
	    degree VARCHAR(100),
	    university VARCHAR(100),
	    country VARCHAR(50),
	    FOREIGN KEY (user_id) REFERENCES users(user_id)  -- Linking to users table
);

-- Insert 20 records into public_info
INSERT INTO public_info (user_id, twitter_handle, degree, university, country) VALUES
(1, '@alice_smith', 'BSc Computer Science', 'MIT', 'USA'),
(2, '@bob_jones', 'MSc Data Science', 'Stanford', 'USA'),
(3, '@charlie_brown', 'BA English Literature', 'Harvard', 'USA'),
(4, '@david_white', 'BSc Physics', 'Cambridge', 'UK'),
(5, '@eve_green', 'MBA Business Administration', 'Oxford', 'UK'),
(6, '@frank_taylor', 'PhD Artificial Intelligence', 'UC Berkeley', 'USA'),
(7, '@grace_wilson', 'BEng Civil Engineering', 'Imperial College', 'UK'),
(8, '@hank_moore', 'LLB Law', 'UCLA', 'USA'),
(9, '@ivy_clark', 'BA Economics', 'Yale', 'USA'),
(10, '@jack_king', 'BSc Mathematics', 'Caltech', 'USA'),
(11, '@kate_scott', 'BSc Biology', 'Princeton', 'USA'),
(12, '@leo_adams', 'MSc Electrical Engineering', 'Georgia Tech', 'USA'),
(13, '@mia_nelson', 'BFA Fine Arts', 'Parsons School of Design', 'USA'),
(14, '@nina_roberts', 'BSc Chemistry', 'University of Toronto', 'Canada'),
(15, '@oscar_walker', 'BA Philosophy', 'University of Chicago', 'USA'),
(16, '@paul_young', 'BSc Environmental Science', 'University of Melbourne', 'Australia'),
(17, '@quinn_harris', 'MSc Artificial Intelligence', 'TU Delft', 'Netherlands'),
(18, '@ray_martin', 'MBA Finance', 'Wharton School', 'USA'),
(19, '@sara_allen', 'BA Political Science', 'Columbia University', 'USA'),
(20, '@tom_lewis', 'BEng Mechanical Engineering', 'University of Michigan', 'USA');

-- Table 4: Access Info (user access data like last login, last post (text), activity)
CREATE TABLE access_info (
	    user_id INT,                          -- Foreign key to users table
	    last_login TIMESTAMP,
	    last_post TEXT,                       -- Post content as text
	    activity_last_week INT,               -- Number of actions in the last week
	    keywords VARCHAR(255),
	    FOREIGN KEY (user_id) REFERENCES users(user_id)  -- Linking to users table
);

-- Insert 20 records into access_info
INSERT INTO access_info (user_id, last_login, last_post, activity_last_week, keywords) VALUES
(1, '2024-10-01 12:00:00', 'Just started learning Python and loving it!', 5, 'tech, programming, AI'),
(2, '2024-10-01 09:00:00', 'Exploring data visualization techniques using Matplotlib.', 7, 'data, machine learning, python'),
(3, '2024-09-30 16:00:00', 'Finished reading a great book on modern literature.', 3, 'books, writing, literature'),
(4, '2024-10-03 08:00:00', 'Can’t wait to see the next Mars mission launch!', 6, 'science, physics, space'),
(5, '2024-09-29 18:00:00', 'Attended a fantastic leadership seminar today!', 4, 'business, marketing, leadership'),
(6, '2024-10-01 14:00:00', 'Successfully trained my AI model for image classification.', 8, 'AI, robotics, research'),
(7, '2024-09-28 11:00:00', 'Starting a new project on sustainable building design.', 2, 'engineering, design, construction'),
(8, '2024-10-02 15:00:00', 'Working on a new case study related to human rights law.', 9, 'law, justice, human rights'),
(9, '2024-09-29 10:00:00', 'Exciting day trading on the stock market today!', 6, 'economics, finance, markets'),
(10, '2024-10-01 18:00:00', 'Challenging math problem solved using linear algebra!', 7, 'math, algebra, statistics'),
(11, '2024-10-02 08:00:00', 'Finished writing my research paper on genetic engineering.', 5, 'biology, genetics, research'),
(12, '2024-10-01 17:00:00', 'Testing out new hardware for IoT devices in my lab.', 8, 'engineering, circuits, hardware'),
(13, '2024-09-30 09:00:00', 'Working on a new abstract painting inspired by nature.', 3, 'art, painting, sculpture'),
(14, '2024-10-02 11:00:00', 'Conducted a successful chemistry experiment on molecular bonding.', 7, 'chemistry, experiments, research'),
(15, '2024-09-29 14:00:00', 'Had a deep debate on ethics and technology in my philosophy class.', 4, 'philosophy, ethics, debate'),
(16, '2024-10-01 19:00:00', 'Wrote a blog post about climate change and its impact on wildlife.', 9, 'environment, ecology, sustainability'),
(17, '2024-09-28 13:00:00', 'Analyzing the latest advancements in AI research from Europe.', 6, 'AI, research, machine learning'),
(18, '2024-10-02 14:00:00', 'Shared my thoughts on the future of fintech innovation.', 7, 'finance, fintech, technology'),
(19, '2024-09-29 16:00:00', 'Learning about political theories and their impact on society.', 5, 'politics, government, society'),
(20, '2024-10-03 10:00:00', 'Published a review on the latest innovations in mechanical engineering.', 8, 'engineering, mechanics, innovation');
