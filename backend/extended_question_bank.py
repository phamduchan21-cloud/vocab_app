"""Additional topic-based questions for the regular quiz flow."""


def _question(question, correct, wrong, explanation, level="A2", transcript=None):
    return {
        "level": level,
        "question": question,
        "options": [correct, *wrong],
        "correctAnswer": 0,
        "explanation": explanation,
        **({"transcript": transcript} if transcript else {}),
    }


def _vocabulary(word, meaning, wrong, level="A2"):
    return _question(
        f'"{word}" nghĩa là gì?',
        meaning,
        wrong,
        f'"{word}" nghĩa là {meaning.lower()}.',
        level,
    )


EXTRA_QUESTION_BANK = {
    "health": {
        "vocabulary": [
            _vocabulary("Symptom", "Triệu chứng", ["Đơn thuốc", "Cuộc hẹn", "Phương pháp điều trị"]),
            _vocabulary("Prescription", "Đơn thuốc", ["Bảo hiểm", "Bệnh nhân", "Phòng khám"], "B1"),
            _vocabulary("Recover", "Hồi phục", ["Bị thương", "Ho", "Đo nhiệt độ"]),
            _vocabulary("Appointment", "Cuộc hẹn", ["Ca phẫu thuật", "Thuốc giảm đau", "Dị ứng"]),
            _vocabulary("Balanced diet", "Chế độ ăn cân bằng", ["Thức ăn nhanh", "Bữa ăn nhẹ", "Chế độ nhịn ăn"], "B1"),
        ],
        "grammar": [
            _question("You ___ drink more water when you exercise.", "should", ["would", "might to", "are"], "Dùng 'should' để đưa ra lời khuyên."),
            _question("She has been ill ___ Monday.", "since", ["for", "during", "from"], "'Since' đi với một mốc thời gian.", "B1"),
            _question("If the pain gets worse, ___ a doctor.", "see", ["saw", "seeing", "to see"], "Câu mệnh lệnh dùng động từ nguyên mẫu."),
            _question("I ___ this medicine twice a day.", "take", ["takes", "am take", "taking"], "Chủ ngữ 'I' dùng động từ nguyên mẫu ở hiện tại đơn."),
            _question("The patient ___ by the nurse right now.", "is being examined", ["examines", "is examining", "was examined"], "Hiện tại tiếp diễn bị động: is being examined.", "B2"),
        ],
        "reading": [
            _question("Vì sao giấc ngủ quan trọng?\n\nGetting enough sleep helps the body repair itself and improves concentration during the day.", "Giúp cơ thể hồi phục và tăng khả năng tập trung", ["Giúp ăn ngon hơn", "Thay thế việc tập thể dục", "Làm giảm nhu cầu uống nước"], "Đoạn văn nêu hai lợi ích: hồi phục và tập trung.", "B1"),
            _question("Người lớn nên vận động bao lâu mỗi tuần?\n\nHealth experts recommend at least 150 minutes of moderate exercise each week for most adults.", "Ít nhất 150 phút", ["30 phút", "60 phút", "300 phút mỗi ngày"], "Đoạn văn nói rõ 'at least 150 minutes'.", "A2"),
            _question("Khi nào cần dùng kháng sinh?\n\nAntibiotics treat bacterial infections, but they do not work against viruses such as the common cold.", "Khi điều trị nhiễm khuẩn theo chỉ định", ["Mỗi khi bị cảm lạnh", "Khi thiếu ngủ", "Sau mọi buổi tập"], "Kháng sinh điều trị nhiễm khuẩn, không trị virus.", "B2"),
            _question("Thói quen nào giúp giảm căng thẳng?\n\nShort breathing exercises and regular breaks can reduce stress during a busy workday.", "Thở sâu và nghỉ giải lao đều đặn", ["Bỏ bữa trưa", "Làm việc liên tục", "Uống nhiều cà phê"], "Đoạn văn đề xuất thở và nghỉ ngắn.", "A2"),
            _question("Vì sao cần đọc nhãn thực phẩm?\n\nFood labels show serving sizes, added sugar, salt, and other information that helps shoppers make healthier choices.", "Để đưa ra lựa chọn ăn uống lành mạnh hơn", ["Để nấu nhanh hơn", "Để tìm món rẻ nhất", "Để tránh mọi chất béo"], "Nhãn cung cấp thông tin dinh dưỡng để lựa chọn tốt hơn.", "B1"),
        ],
        "listening": [
            _question("Bệnh nhân cần uống thuốc khi nào?", "Sau bữa sáng và bữa tối", ["Trước khi ngủ", "Chỉ vào buổi trưa", "Mỗi khi thấy đau"], "'After breakfast and after dinner'.", transcript="Take one tablet after breakfast and another after dinner. Please do not take it on an empty stomach."),
            _question("Cuộc hẹn được chuyển sang lúc mấy giờ?", "Ba giờ chiều", ["Mười giờ sáng", "Hai giờ chiều", "Bốn giờ chiều"], "'Move your appointment to three p.m.'.", transcript="Hello, this is Green Clinic. We need to move your appointment from ten in the morning to three in the afternoon."),
            _question("Người nói bị đau ở đâu?", "Mắt cá chân", ["Đầu gối", "Vai", "Cổ tay"], "'My ankle still hurts'.", transcript="I fell while running yesterday. My ankle still hurts, especially when I walk upstairs."),
            _question("Bác sĩ khuyên người nghe làm gì?", "Nghỉ ngơi và uống nhiều nước", ["Đi làm ngay", "Tập thể dục nặng", "Bỏ bữa sáng"], "'Get some rest and drink plenty of water'.", transcript="Your temperature is a little high. Get some rest and drink plenty of water today."),
            _question("Lớp yoga bắt đầu khi nào?", "Sáu giờ ba mươi tối thứ Năm", ["Sáu giờ sáng thứ Năm", "Bảy giờ tối thứ Sáu", "Năm giờ ba mươi chiều"], "'Thursday at six thirty in the evening'.", transcript="The beginner yoga class starts this Thursday at six thirty in the evening. Please arrive ten minutes early."),
        ],
    },
    "education": {
        "vocabulary": [
            _vocabulary("Assignment", "Bài tập được giao", ["Học kỳ", "Điểm số", "Học bổng"]),
            _vocabulary("Scholarship", "Học bổng", ["Học phí", "Giáo trình", "Kỳ thi"], "B1"),
            _vocabulary("Curriculum", "Chương trình học", ["Thư viện", "Bằng tốt nghiệp", "Lớp học"], "B2"),
            _vocabulary("Graduate", "Tốt nghiệp", ["Đăng ký môn", "Ôn tập", "Nghỉ học"]),
            _vocabulary("Tuition fee", "Học phí", ["Tiền thuê nhà", "Phí thư viện", "Tiền thưởng"], "B1"),
        ],
        "grammar": [
            _question("I ___ my homework yet.", "haven't finished", ["didn't finish", "don't finished", "am not finish"], "'Yet' thường đi với hiện tại hoàn thành.", "B1"),
            _question("Students must ___ their essays by Friday.", "submit", ["submitted", "submitting", "to submitted"], "Sau 'must' dùng động từ nguyên mẫu."),
            _question("This book is ___ than the previous one.", "more useful", ["usefuler", "most useful", "more use"], "So sánh hơn của tính từ dài: more useful."),
            _question("If I study hard, I ___ the exam.", "will pass", ["passed", "would pass", "passing"], "Câu điều kiện loại 1 dùng will ở mệnh đề chính."),
            _question("The lecture ___ before we arrived.", "had started", ["has started", "starts", "was starting"], "Hành động xảy ra trước một mốc quá khứ dùng quá khứ hoàn thành.", "B2"),
        ],
        "reading": [
            _question("Thư viện đóng cửa lúc mấy giờ trong tuần thi?\n\nDuring exam week, the university library stays open until midnight from Monday to Friday.", "Nửa đêm", ["Chín giờ tối", "Mười giờ tối", "Suốt 24 giờ"], "'Until midnight' = đến nửa đêm."),
            _question("Sinh viên có thể nhận góp ý bằng cách nào?\n\nStudents can upload a draft to the course website and receive written feedback from their tutor.", "Tải bản nháp lên trang khóa học", ["Gửi qua bưu điện", "Nộp tại thư viện", "Gọi điện cho giáo viên"], "Đoạn văn hướng dẫn tải bản nháp lên website."),
            _question("Lợi ích của học theo nhóm là gì?\n\nStudy groups allow learners to explain ideas to one another and notice gaps in their own understanding.", "Giải thích ý tưởng và nhận ra phần kiến thức còn thiếu", ["Không cần tự học", "Được miễn thi", "Giảm học phí"], "Đây là hai lợi ích được nêu trong đoạn.", "B1"),
            _question("Khóa học trực tuyến phù hợp với ai?\n\nThe course is self-paced, so learners can complete each module whenever their schedule allows.", "Người cần lịch học linh hoạt", ["Chỉ học sinh toàn thời gian", "Người không có internet", "Chỉ giáo viên"], "Self-paced cho phép học theo lịch cá nhân."),
            _question("Điều kiện để được cấp chứng chỉ là gì?\n\nTo receive the certificate, participants must complete every lesson and score at least seventy percent on the final test.", "Hoàn thành mọi bài và đạt ít nhất 70%", ["Chỉ cần đăng ký", "Tham gia một nửa số buổi", "Đạt đúng 50%"], "Đoạn văn nêu hai điều kiện rõ ràng.", "B2"),
        ],
        "listening": [
            _question("Bài tập phải nộp khi nào?", "Trước trưa thứ Hai", ["Tối thứ Hai", "Trưa thứ Sáu", "Sáng Chủ nhật"], "'By noon on Monday'.", transcript="Please upload your assignment by noon on Monday. Late work will lose ten percent of the final mark."),
            _question("Lớp học chuyển đến phòng nào?", "Phòng 305", ["Phòng 205", "Phòng 350", "Thư viện"], "'Moved to room three oh five'.", transcript="Today's English class has moved from room two oh five to room three oh five on the third floor."),
            _question("Sinh viên cần mang gì đến phòng thi?", "Thẻ sinh viên và bút chì", ["Máy tính xách tay", "Giáo trình", "Điện thoại"], "'Bring your student card and two pencils'.", transcript="Remember to bring your student card and two pencils to the exam. Mobile phones must remain outside."),
            _question("Giáo viên sẽ trả kết quả khi nào?", "Chiều thứ Sáu", ["Sáng thứ Hai", "Chiều thứ Tư", "Tuần sau"], "'Return your test results on Friday afternoon'.", transcript="I will return your test results on Friday afternoon and discuss the most common mistakes."),
            _question("Câu lạc bộ hội thoại họp ở đâu?", "Quán cà phê cạnh thư viện", ["Trong lớp học", "Nhà thi đấu", "Cổng trường"], "'At the cafe next to the library'.", transcript="The English conversation club meets every Wednesday at the cafe next to the library."),
        ],
    },
    "technology": {
        "vocabulary": [
            _vocabulary("Device", "Thiết bị", ["Mật khẩu", "Tệp tin", "Mạng xã hội"]),
            _vocabulary("Update", "Cập nhật", ["Xóa dữ liệu", "Tắt nguồn", "Sao chép"]),
            _vocabulary("Privacy", "Quyền riêng tư", ["Tốc độ mạng", "Dung lượng pin", "Độ sáng"], "B1"),
            _vocabulary("Backup", "Bản sao lưu", ["Phần mềm độc hại", "Tài khoản", "Màn hình"], "B1"),
            _vocabulary("Artificial intelligence", "Trí tuệ nhân tạo", ["Thực tế ảo", "Mạng không dây", "Bộ nhớ ngoài"], "B2"),
        ],
        "grammar": [
            _question("You should ___ your password regularly.", "change", ["changed", "changing", "to changing"], "Sau 'should' dùng động từ nguyên mẫu."),
            _question("The file ___ automatically every five minutes.", "is saved", ["saves", "is saving", "saved"], "Hiện tại đơn bị động: is saved.", "B1"),
            _question("My phone has run ___ of battery.", "out", ["off", "away", "over"], "Cụm 'run out of' nghĩa là hết."),
            _question("This app is easier ___ the old one.", "to use than", ["using that", "use then", "to use as"], "Cấu trúc so sánh: easier to use than."),
            _question("By 2030, AI ___ many routine tasks.", "will have automated", ["automated", "automates", "has automate"], "Tương lai hoàn thành diễn tả việc hoàn tất trước một mốc tương lai.", "B2"),
        ],
        "reading": [
            _question("Xác thực hai bước tăng bảo mật bằng cách nào?\n\nTwo-factor authentication asks for a second proof of identity in addition to a password.", "Yêu cầu thêm một bằng chứng xác minh", ["Dùng mật khẩu ngắn hơn", "Tắt mã hóa", "Chia sẻ tài khoản"], "Nó bổ sung bước xác minh thứ hai.", "B1"),
            _question("Vì sao nên sao lưu dữ liệu?\n\nA backup protects important files if a device is lost, damaged, or infected by malware.", "Để khôi phục tệp khi thiết bị gặp sự cố", ["Để tăng độ sáng", "Để sạc nhanh hơn", "Để giảm kích thước màn hình"], "Bản sao lưu giúp bảo vệ và khôi phục tệp."),
            _question("Bản cập nhật phần mềm thường bao gồm gì?\n\nSoftware updates often fix security weaknesses and improve stability, not just add new features.", "Sửa lỗ hổng bảo mật và tăng độ ổn định", ["Chỉ đổi biểu tượng", "Xóa mọi tệp cá nhân", "Luôn làm máy chậm hơn"], "Đoạn văn nhấn mạnh bảo mật và ổn định.", "B1"),
            _question("Trí tuệ nhân tạo tạo sinh có thể làm gì?\n\nGenerative AI can produce text, images, and audio from instructions, but its output still needs human review.", "Tạo nội dung từ hướng dẫn", ["Luôn đưa ra thông tin đúng", "Thay thế hoàn toàn con người", "Chỉ xử lý số"], "Generative AI tạo nhiều dạng nội dung từ prompt.", "B2"),
            _question("Vì sao không nên dùng cùng một mật khẩu?\n\nReusing one password means a single data breach can expose several of your accounts.", "Một vụ rò rỉ có thể ảnh hưởng nhiều tài khoản", ["Khó đăng nhập hơn", "Làm pin nhanh hết", "Giảm tốc độ mạng"], "Một mật khẩu bị lộ có thể mở nhiều tài khoản.", "B1"),
        ],
        "listening": [
            _question("Người dùng cần làm gì trước khi cập nhật?", "Cắm sạc điện thoại", ["Xóa mọi ứng dụng", "Tắt Wi-Fi", "Tháo thẻ SIM"], "'Connect your phone to a charger'.", transcript="Before installing the update, connect your phone to a charger and make sure you have a stable Wi-Fi connection."),
            _question("Vì sao người nói không mở được tệp?", "Không có quyền truy cập", ["Tệp quá nhỏ", "Máy hết pin", "Mạng quá nhanh"], "'I do not have permission to access it'.", transcript="Could you share the document again? The link works, but I do not have permission to access it."),
            _question("Cuộc gọi video bị gián đoạn do đâu?", "Kết nối internet không ổn định", ["Mic bị tắt", "Camera quá sáng", "Máy tính hết bộ nhớ"], "'Internet connection is unstable'.", transcript="Your voice keeps cutting out because the internet connection is unstable. Let's turn off our cameras for a moment."),
            _question("Mã xác minh có hiệu lực bao lâu?", "Mười phút", ["Một phút", "Một giờ", "Cả ngày"], "'The code will expire in ten minutes'.", transcript="We sent a verification code to your email address. The code will expire in ten minutes."),
            _question("Bộ phận hỗ trợ đề nghị làm gì đầu tiên?", "Khởi động lại bộ định tuyến", ["Mua máy mới", "Đổi mật khẩu", "Cài lại hệ điều hành"], "'Restart your router first'.", transcript="Please restart your router first. If the problem continues, call our support team again."),
        ],
    },
    "daily_life": {
        "vocabulary": [
            _vocabulary("Household chores", "Việc nhà", ["Thói quen buổi sáng", "Đồ nội thất", "Hàng xóm"], "B1"),
            _vocabulary("Commute", "Đi lại hằng ngày giữa nhà và nơi làm việc", ["Đi nghỉ dưỡng", "Chuyển nhà", "Đi mua sắm"], "B1"),
            _vocabulary("Laundry", "Quần áo cần giặt / việc giặt giũ", ["Bát đĩa", "Rác thải", "Tiền thuê nhà"]),
            _vocabulary("Routine", "Thói quen thường ngày", ["Cuộc hẹn bất ngờ", "Kỳ nghỉ", "Bữa tiệc"]),
            _vocabulary("Neighborhood", "Khu phố", ["Phòng khách", "Trung tâm mua sắm", "Văn phòng"]),
        ],
        "grammar": [
            _question("I usually ___ up at six thirty.", "get", ["gets", "am getting", "gotten"], "Hiện tại đơn diễn tả thói quen."),
            _question("There isn't ___ milk left in the fridge.", "any", ["some", "many", "few"], "Câu phủ định thường dùng 'any'."),
            _question("Could you help me ___ the dishes?", "wash", ["washed", "washing to", "to washed"], "Sau 'help me' có thể dùng động từ nguyên mẫu."),
            _question("She ___ dinner when the doorbell rang.", "was cooking", ["cooks", "has cooked", "is cook"], "Quá khứ tiếp diễn cho hành động đang xảy ra.", "B1"),
            _question("The earlier I leave, the ___ the traffic is.", "lighter", ["light", "lightest", "more lightly"], "Cấu trúc so sánh kép: the earlier..., the lighter....", "B2"),
        ],
        "reading": [
            _question("Minh chuẩn bị bữa trưa khi nào?\n\nMinh prepares his lunch the night before so he does not have to rush in the morning.", "Tối hôm trước", ["Sáng sớm", "Trong giờ nghỉ trưa", "Cuối tuần"], "'The night before' = tối hôm trước."),
            _question("Tại sao tòa nhà phân loại rác?\n\nResidents separate paper, plastic, and food waste so more material can be recycled.", "Để tái chế được nhiều vật liệu hơn", ["Để giảm số cư dân", "Để tăng tiền thuê", "Để bỏ tất cả rác cùng nhau"], "Việc phân loại giúp tăng khả năng tái chế."),
            _question("Chợ cuối tuần mở lúc nào?\n\nThe neighborhood market opens at seven every Saturday and closes shortly after noon.", "Bảy giờ sáng thứ Bảy", ["Bảy giờ tối", "Trưa Chủ nhật", "Cả tuần"], "Đoạn văn nói rõ thời gian mở cửa."),
            _question("Lợi ích của danh sách việc cần làm là gì?\n\nA short to-do list helps people focus on their most important tasks without feeling overwhelmed.", "Giúp tập trung vào việc quan trọng", ["Làm mọi việc cùng lúc", "Không cần nghỉ ngơi", "Ghi nhớ mọi số điện thoại"], "Danh sách ngắn giúp tập trung và bớt quá tải.", "B1"),
            _question("Vì sao Lan đi xe buýt sớm hơn?\n\nLan takes an earlier bus on rainy days because traffic near her office becomes much slower.", "Vì giao thông chậm hơn khi trời mưa", ["Vì xe buýt miễn phí", "Vì văn phòng đóng sớm", "Vì cô ấy thích đi bộ"], "Mưa làm giao thông gần văn phòng chậm hơn."),
        ],
        "listening": [
            _question("Người nói cần mua gì?", "Sữa và trứng", ["Bánh mì và cà phê", "Gạo và thịt", "Trái cây và nước"], "'Pick up some milk and eggs'.", transcript="Could you pick up some milk and eggs on your way home? We already have enough bread."),
            _question("Máy giặt sẽ chạy trong bao lâu?", "Bốn mươi phút", ["Hai mươi phút", "Một giờ", "Mười lăm phút"], "'The cycle will take forty minutes'.", transcript="I have just started the washing machine. The cycle will take forty minutes."),
            _question("Bưu kiện được để ở đâu?", "Với hàng xóm phòng 402", ["Trước cửa", "Ở bưu điện", "Trong thang máy"], "'Left your package with your neighbor in apartment four oh two'.", transcript="You were not home, so I left your package with your neighbor in apartment four oh two."),
            _question("Bữa tối bắt đầu lúc mấy giờ?", "Bảy giờ", ["Sáu giờ", "Bảy giờ ba mươi", "Tám giờ"], "'Dinner will be ready at seven'.", transcript="Dinner will be ready at seven. Please set the table before the guests arrive."),
            _question("Vì sao tàu điện đông hơn bình thường?", "Một tuyến xe buýt đang đóng", ["Vé được giảm giá", "Trời nắng", "Có trận bóng"], "'The number twelve bus route is closed'.", transcript="The train is busier than usual this morning because the number twelve bus route is closed."),
        ],
    },
}


EXTRA_TOPIC_ALIASES = {
    "health": "Sức khỏe",
    "education": "Giáo dục",
    "technology": "Công nghệ",
    "daily_life": "Cuộc sống hằng ngày",
}
