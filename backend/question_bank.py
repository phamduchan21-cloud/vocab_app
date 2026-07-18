"""
Question bank — 200 câu hỏi parsed từ quiz_question_bank.md.
Chia theo chủ đề (topic) và kỹ năng (skill_type).
Mỗi câu hỏi gồm: level, question, options (4 đáp án đã shuffle), correctAnswer, explanation, transcript (nếu có).
"""

import random

from extended_question_bank import EXTRA_QUESTION_BANK, EXTRA_TOPIC_ALIASES

QUESTION_BANK = {
    "family": {
        "vocabulary": [
            {"level": "A1", "question": '"Niece" nghĩa là gì?', "options": ["Cháu gái (con của anh/chị/em)", "Cháu trai", "Em họ", "Con dâu"], "correctAnswer": 0, "explanation": "\"Niece\" là cháu gái, con của anh chị em ruột."},
            {"level": "B1", "question": '"Sibling" nghĩa là gì?', "options": ["Anh/chị/em ruột", "Con nuôi", "Người yêu", "Vợ/chồng"], "correctAnswer": 0, "explanation": "\"Sibling\" chỉ chung anh, chị hoặc em ruột."},
            {"level": "A2", "question": '"Twins" nghĩa là gì?', "options": ["Anh em họ", "Cặp song sinh", "Cháu nội", "Con riêng"], "correctAnswer": 1, "explanation": "\"Twins\" là cặp sinh đôi."},
            {"level": "B2", "question": '"Only child" nghĩa là gì?', "options": ["Con một", "Con út", "Con cả", "Con nuôi"], "correctAnswer": 0, "explanation": "\"Only child\" là con một trong gia đình."},
            {"level": "C1", "question": '"Estranged" (nói về quan hệ gia đình) nghĩa là gì?', "options": ["Rất thân thiết", "Mới sinh", "Mới kết hôn", "Xa cách, không còn liên lạc"], "correctAnswer": 3, "explanation": "\"Estranged\" diễn tả mối quan hệ đã rạn nứt, không còn gắn bó."},
        ],
        "grammar": [
            {"level": "A2", "question": "My parents ___ very supportive.", "options": ["is", "are", "am", "was"], "correctAnswer": 1, "explanation": "Chủ ngữ số nhiều \"parents\" đi với \"are\"."},
            {"level": "B1", "question": "She is very close ___ her grandmother.", "options": ["to", "with", "for", "at"], "correctAnswer": 0, "explanation": "Cụm cố định: \"close to someone\"."},
            {"level": "A2", "question": "___ your brother live with you?", "options": ["Does", "Do", "Is", "Are"], "correctAnswer": 0, "explanation": "Chủ ngữ số ít \"your brother\" dùng trợ động từ \"does\"."},
            {"level": "B1", "question": "This is the woman ___ helped raise me.", "options": ["who", "whom", "whose", "which"], "correctAnswer": 0, "explanation": "\"Who\" làm chủ ngữ trong mệnh đề quan hệ chỉ người."},
            {"level": "B2", "question": "I ___ my cousin since we were children.", "options": ["know", "knew", "have known", "am knowing"], "correctAnswer": 2, "explanation": "\"Since\" đi với thì hiện tại hoàn thành: \"have known\"."},
        ],
        "reading": [
            {"level": "B1", "question": "Gia đình Lan tụ họp ở đâu?\n\nEvery summer, Lan's family gathers at her grandparents' house in Da Lat. Her cousins come from Ho Chi Minh City and Hanoi.", "options": ["Nhà ông bà ở Đà Lạt", "Nhà ở Hà Nội", "Một khách sạn", "Nhà ở TP.HCM"], "correctAnswer": 0, "explanation": "Đoạn văn nói rõ: 'gathers at her grandparents' house in Da Lat'."},
            {"level": "A2", "question": "Tuấn có mấy chị em gái?\n\nTuan has three sisters. He is the only boy in the family.", "options": ["Ba", "Hai", "Một", "Bốn"], "correctAnswer": 0, "explanation": "Có 'three sisters'."},
            {"level": "B2", "question": "Ý chính của đoạn văn là gì?\n\nMany young Vietnamese families now live separately from their parents... they still visit on weekends... keeping strong family bonds.", "options": ["Các gia đình trẻ sống riêng nhưng vẫn giữ mối liên kết chặt chẽ", "Gia đình trẻ không còn quan tâm đến cha mẹ", "Người Việt không còn tổ chức lễ hội gia đình", "Ông bà không muốn sống cùng con cháu"], "correctAnswer": 0, "explanation": "Đoạn văn nhấn mạnh sự gắn kết dù sống riêng."},
            {"level": "B1", "question": "Ông bà thường làm gì khi cha mẹ đi làm cả ngày?\n\nGrandparents often play an important role in raising children in Vietnam.", "options": ["Giúp nuôi dạy cháu và truyền dạy giá trị truyền thống", "Chỉ trông nhà", "Không tham gia vào việc nuôi dạy", "Đi làm thay cha mẹ"], "correctAnswer": 0, "explanation": "Ông bà giúp nuôi dạy cháu và truyền dạy giá trị truyền thống."},
            {"level": "C1", "question": "Theo đoạn văn, điều gì đang thay đổi ở khu vực thành thị?\n\nThe concept of the nuclear family has gradually replaced the extended family model in many urban areas.", "options": ["Mô hình gia đình hạt nhân dần thay thế gia đình nhiều thế hệ", "Gia đình nông thôn đang biến mất", "Không còn ai sống cùng cha mẹ", "Gia đình thành thị đông con hơn"], "correctAnswer": 0, "explanation": "Đoạn văn nói gia đình hạt nhân thay thế gia đình nhiều thế hệ ở thành thị."},
        ],
        "listening": [
            {"level": "A2", "transcript": "Hi, I'm Minh. I have one older brother and two younger sisters. We live with our parents in Hanoi.", "question": "Minh có bao nhiêu anh chị em?", "options": ["Ba", "Hai", "Một", "Bốn"], "correctAnswer": 0, "explanation": "Minh có 1 anh trai + 2 em gái = 3 anh chị em."},
            {"level": "A1", "transcript": "This is my mom. She is a teacher. She works at a primary school near our house.", "question": "Mẹ của người nói làm nghề gì?", "options": ["Giáo viên", "Bác sĩ", "Kỹ sư", "Nhân viên bán hàng"], "correctAnswer": 0, "explanation": "Người nói nói: 'She is a teacher'."},
            {"level": "B1", "transcript": "Let's plan the family trip for Tet. I think we should book the train tickets now before they sell out.", "question": "Người nói muốn làm gì trước khi vé được bán hết?", "options": ["Đặt vé tàu", "Đặt vé máy bay", "Đặt phòng khách sạn", "Mua quà Tết"], "correctAnswer": 0, "explanation": "'book the train tickets now before they sell out'."},
            {"level": "B2", "transcript": "I know we disagreed last week, but family is more important than being right. Let's talk it through calmly this weekend.", "question": "Người nói đề xuất điều gì?", "options": ["Nói chuyện bình tĩnh để giải quyết mâu thuẫn", "Tránh gặp mặt nhau", "Nhờ người khác phân xử", "Chấm dứt mối quan hệ"], "correctAnswer": 0, "explanation": "'Let's talk it through calmly' — đề xuất nói chuyện bình tĩnh."},
            {"level": "A2", "transcript": "Our dog, Coco, has been part of our family for five years now.", "question": "Coco đã ở với gia đình bao lâu?", "options": ["Năm năm", "Ba năm", "Một năm", "Mười năm"], "correctAnswer": 0, "explanation": "'for five years' = năm năm."},
        ],
    },
    "travel": {
        "vocabulary": [
            {"level": "A1", "question": '"Luggage" nghĩa là gì?', "options": ["Hành lý", "Vé máy bay", "Hộ chiếu", "Sân bay"], "correctAnswer": 0, "explanation": "\"Luggage\" là hành lý."},
            {"level": "B2", "question": '"Itinerary" nghĩa là gì?', "options": ["Lịch trình chuyến đi", "Vé một chiều", "Nhà nghỉ", "Hải quan"], "correctAnswer": 0, "explanation": "\"Itinerary\" là lịch trình chuyến đi."},
            {"level": "A2", "question": '"Round-trip ticket" nghĩa là gì?', "options": ["Vé khứ hồi", "Vé một chiều", "Vé hạng thương gia", "Vé giảm giá"], "correctAnswer": 0, "explanation": "\"Round-trip ticket\" là vé khứ hồi."},
            {"level": "B1", "question": '"To check in" (ở sân bay/khách sạn) nghĩa là gì?', "options": ["Làm thủ tục nhận phòng/lên máy bay", "Trả phòng", "Đặt chỗ trước", "Hủy chuyến"], "correctAnswer": 0, "explanation": "\"Check in\" là làm thủ tục nhận phòng hoặc làm thủ tục lên máy bay."},
            {"level": "C1", "question": '"Off the beaten path" nghĩa là gì?', "options": ["Nơi ít khách du lịch, chưa nổi tiếng", "Con đường chính", "Địa điểm nguy hiểm", "Tuyến đường tắc nghẽn"], "correctAnswer": 0, "explanation": "\"Off the beaten path\" là nơi ít khách du lịch."},
        ],
        "grammar": [
            {"level": "A2", "question": "We ___ to Da Nang last week.", "options": ["go", "goes", "went", "going"], "correctAnswer": 2, "explanation": "Quá khứ đơn: \"went\"."},
            {"level": "B1", "question": "By the time we arrived, the plane ___ already ___.", "options": ["has / left", "had / left", "have / left", "was / leaving"], "correctAnswer": 1, "explanation": "Quá khứ hoàn thành: \"had already left\"."},
            {"level": "A2", "question": "I ___ visiting Hoi An next month.", "options": ["am", "is", "was", "be"], "correctAnswer": 0, "explanation": "\"Am\" đi với chủ ngữ \"I\", diễn tả kế hoạch tương lai."},
            {"level": "B2", "question": "If I ___ more time, I would explore the whole city.", "options": ["have", "had", "will have", "having"], "correctAnswer": 1, "explanation": "Câu điều kiện loại 2 dùng quá khứ đơn ở mệnh đề if."},
            {"level": "B1", "question": "This is the hotel ___ we stayed last summer.", "options": ["where", "which", "who", "when"], "correctAnswer": 0, "explanation": "\"Where\" dùng cho mệnh đề quan hệ chỉ nơi chốn."},
        ],
        "reading": [
            {"level": "B2", "question": "Vì sao du khách trẻ chọn xe khách qua đêm và nhà trọ?\n\nBackpacking through Southeast Asia has become popular among young travelers seeking affordable adventures. Many choose overnight buses and hostels to save money.", "options": ["Để tiết kiệm tiền cho trải nghiệm", "Vì không có khách sạn", "Vì bắt buộc theo luật", "Vì thích cảm giác mạo hiểm"], "correctAnswer": 0, "explanation": "Họ chọn để tiết kiệm tiền."},
            {"level": "A2", "question": "Mùa nào là thời điểm tốt để xem ruộng bậc thang vàng ở Sapa?\n\nSapa is famous for its terraced rice fields. Many tourists visit in September and October.", "options": ["Tháng 9 và 10", "Tháng 1 và 2", "Mùa hè", "Mùa đông"], "correctAnswer": 0, "explanation": "Du khách đến vào tháng 9 và 10."},
            {"level": "B1", "question": "Du khách nên làm gì trước khi ra nước ngoài?\n\nBefore traveling abroad, it's important to check visa requirements, exchange currency, and make copies of important documents.", "options": ["Kiểm tra visa, đổi tiền, sao chép giấy tờ quan trọng", "Chỉ cần mua vé máy bay", "Không cần chuẩn bị gì", "Chỉ cần đặt khách sạn"], "correctAnswer": 0, "explanation": "Đoạn văn liệt kê 3 việc cần làm."},
            {"level": "C1", "question": "Một số điểm đến đã làm gì để bảo tồn di sản?\n\nOvertourism has become a growing concern. Some destinations have begun limiting visitor numbers to preserve their heritage.", "options": ["Giới hạn số lượng khách du lịch", "Tăng giá vé máy bay", "Xây thêm khách sạn", "Cấm du lịch hoàn toàn"], "correctAnswer": 0, "explanation": "'Limiting visitor numbers' = giới hạn số lượng du khách."},
            {"level": "B1", "question": "Bảo hiểm du lịch có thể chi trả cho điều gì?\n\nTravel insurance can cover unexpected costs such as medical emergencies, lost luggage, or trip cancellations.", "options": ["Cấp cứu y tế, thất lạc hành lý, hủy chuyến đi", "Chỉ chi phí ăn uống", "Chỉ chi phí khách sạn", "Không chi trả gì cả"], "correctAnswer": 0, "explanation": "Bảo hiểm du lịch chi trả các rủi ro bất ngờ."},
        ],
        "listening": [
            {"level": "B1", "transcript": "Attention passengers, flight VN214 to Singapore has been delayed by two hours due to weather conditions.", "question": "Chuyến bay bị trễ bao lâu?", "options": ["Hai giờ", "Một giờ", "Ba mươi phút", "Bốn giờ"], "correctAnswer": 0, "explanation": "'Delayed by two hours' = trễ hai giờ."},
            {"level": "A2", "transcript": "Welcome to the hotel. Breakfast is served from seven to ten in the morning, on the second floor.", "question": "Bữa sáng được phục vụ ở tầng nào?", "options": ["Tầng hai", "Tầng một", "Tầng ba", "Tầng trệt"], "correctAnswer": 0, "explanation": "'On the second floor' = tầng hai."},
            {"level": "A1", "transcript": "Excuse me, where is the nearest train station? Is it far from here?", "question": "Người nói đang hỏi về điều gì?", "options": ["Vị trí ga tàu gần nhất", "Giá vé tàu", "Giờ tàu chạy", "Cách mua vé"], "correctAnswer": 0, "explanation": "'Where is the nearest train station' = ga tàu gần nhất."},
            {"level": "B2", "transcript": "Due to heavy traffic, our tour bus will be about thirty minutes behind schedule.", "question": "Điều gì khiến xe bus bị trễ?", "options": ["Giao thông đông đúc", "Xe hỏng", "Thời tiết xấu", "Thiếu tài xế"], "correctAnswer": 0, "explanation": "'Due to heavy traffic' = vì giao thông đông đúc."},
            {"level": "B1", "transcript": "You can exchange currency at the airport, but the rate is better at banks downtown. I'd recommend waiting until you get to the city center.", "question": "Người nói khuyên nên đổi tiền ở đâu để có tỷ giá tốt hơn?", "options": ["Ngân hàng ở trung tâm thành phố", "Sân bay", "Khách sạn", "Chợ đen"], "correctAnswer": 0, "explanation": "'The rate is better at banks downtown'."},
        ],
    },
    "work": {
        "vocabulary": [
            {"level": "A2", "question": '"Deadline" nghĩa là gì?', "options": ["Hạn chót", "Kỳ nghỉ", "Lương thưởng", "Cuộc họp"], "correctAnswer": 0, "explanation": "\"Deadline\" là hạn chót."},
            {"level": "C1", "question": '"To delegate a task" nghĩa là gì?', "options": ["Giao/ủy quyền một nhiệm vụ cho người khác", "Hoàn thành nhiệm vụ một mình", "Từ chối nhiệm vụ", "Trì hoãn nhiệm vụ"], "correctAnswer": 0, "explanation": "\"Delegate\" là ủy quyền/giao việc."},
            {"level": "B1", "question": '"Promotion" nghĩa là gì?', "options": ["Thăng chức", "Sa thải", "Nghỉ việc", "Đào tạo"], "correctAnswer": 0, "explanation": "\"Promotion\" là thăng chức."},
            {"level": "A2", "question": '"Resume/CV" nghĩa là gì?', "options": ["Sơ yếu lý lịch", "Hợp đồng lao động", "Đơn xin nghỉ phép", "Bảng lương"], "correctAnswer": 0, "explanation": "\"Resume/CV\" là sơ yếu lý lịch."},
            {"level": "B2", "question": '"Work-life balance" nghĩa là gì?', "options": ["Sự cân bằng giữa công việc và cuộc sống", "Làm việc ngoài giờ", "Nghỉ hưu sớm", "Làm nhiều công việc cùng lúc"], "correctAnswer": 0, "explanation": "\"Work-life balance\" là cân bằng công việc và cuộc sống."},
        ],
        "grammar": [
            {"level": "B1", "question": "By next year, I ___ at this company for five years.", "options": ["will work", "will have worked", "worked", "am working"], "correctAnswer": 1, "explanation": "Tương lai hoàn thành: \"will have worked\"."},
            {"level": "A2", "question": "She works ___ a marketing manager.", "options": ["as", "for", "in", "at"], "correctAnswer": 0, "explanation": "\"Work as\" = làm việc với vị trí."},
            {"level": "B2", "question": "The report ___ by tomorrow morning.", "options": ["must finish", "must be finished", "must finished", "must have finish"], "correctAnswer": 1, "explanation": "Câu bị động với động từ khuyết thiếu: \"must be finished\"."},
            {"level": "B1", "question": "I would rather ___ from home today.", "options": ["work", "to work", "working", "worked"], "correctAnswer": 0, "explanation": "\"Would rather\" theo sau là động từ nguyên mẫu không \"to\"."},
            {"level": "C1", "question": "Not only ___ the deadline, but he also improved the quality of the report.", "options": ["he met", "did he meet", "he did meet", "meeting he"], "correctAnswer": 1, "explanation": "Đảo ngữ sau \"Not only\" ở đầu câu: \"did he meet\"."},
        ],
        "reading": [
            {"level": "B2", "question": "Các nhà quản lý hiện nay tập trung vào điều gì?\n\nRemote work has changed how companies evaluate productivity. Instead of tracking hours, many managers now focus on measurable outcomes.", "options": ["Kết quả công việc có thể đo lường được", "Số giờ có mặt ở văn phòng", "Số lượng email gửi đi", "Trang phục của nhân viên"], "correctAnswer": 0, "explanation": "'Focus on measurable outcomes and project deliverables'."},
            {"level": "A2", "question": "Nam đi làm bằng phương tiện gì?\n\nNam works at a bank in the city center. He takes the bus to work every day.", "options": ["Xe buýt", "Xe máy", "Ô tô riêng", "Đi bộ"], "correctAnswer": 0, "explanation": "'Takes the bus' = đi xe buýt."},
            {"level": "B1", "question": "Ứng viên nên chuẩn bị điều gì trước phỏng vấn?\n\nA good job interview requires preparation: researching the company, practicing common questions, and dressing appropriately.", "options": ["Nghiên cứu công ty, luyện tập câu hỏi, ăn mặc phù hợp", "Chỉ cần đến đúng giờ", "Không cần chuẩn bị gì", "Chỉ cần mang theo CV"], "correctAnswer": 0, "explanation": "Đoạn văn liệt kê 3 việc cần chuẩn bị."},
            {"level": "C1", "question": "Vì sao kỹ năng mềm ngày càng được coi trọng?\n\nAs automation handles routine tasks, employers value soft skills such as critical thinking, adaptability, and emotional intelligence.", "options": ["Vì máy móc khó thay thế được chúng", "Vì công việc thủ công không còn cần thiết", "Vì lương cao hơn", "Vì dễ học hơn kỹ năng cứng"], "correctAnswer": 0, "explanation": "Kỹ năng mềm khó thay thế bằng máy móc."},
            {"level": "B1", "question": "Nhược điểm của công việc freelance là gì?\n\nFreelancing offers flexibility but also comes with irregular income and the responsibility of finding one's own clients.", "options": ["Thu nhập không ổn định và phải tự tìm khách hàng", "Không được chọn dự án", "Giờ làm việc cố định", "Không có tự do"], "correctAnswer": 0, "explanation": "\"Irregular income and finding one's own clients\"."},
        ],
        "listening": [
            {"level": "B2", "transcript": "Good morning everyone. Before we start, I'd like to remind you that the quarterly report is due this Friday, not next Monday as originally planned.", "question": "Báo cáo quý cần nộp vào khi nào?", "options": ["Thứ Sáu tuần này", "Thứ Hai tuần sau", "Thứ Sáu tuần sau", "Cuối tháng"], "correctAnswer": 0, "explanation": "'Due this Friday' = hạn nộp thứ Sáu tuần này."},
            {"level": "A2", "transcript": "Hi, this is Mai calling about the job application. Could you tell me the interview will be on Tuesday or Wednesday?", "question": "Mai gọi điện để hỏi về điều gì?", "options": ["Ngày phỏng vấn", "Mức lương", "Địa chỉ công ty", "Thời gian làm việc"], "correctAnswer": 0, "explanation": "'Could you tell me the interview will be on Tuesday or Wednesday?'"},
            {"level": "B1", "transcript": "We're hiring a new marketing assistant. The role requires strong writing skills and at least one year of experience.", "question": "Vị trí tuyển dụng yêu cầu điều gì?", "options": ["Kỹ năng viết tốt và ít nhất một năm kinh nghiệm", "Bằng thạc sĩ", "Biết nhiều ngôn ngữ", "Kinh nghiệm quản lý"], "correctAnswer": 0, "explanation": "'Strong writing skills and at least one year of experience'."},
            {"level": "B2", "transcript": "I think we should postpone the product launch. The testing phase revealed several bugs that need to be fixed first.", "question": "Người nói đề xuất điều gì?", "options": ["Hoãn ra mắt sản phẩm để sửa lỗi", "Ra mắt sản phẩm ngay", "Hủy dự án", "Thuê thêm nhân viên"], "correctAnswer": 0, "explanation": "'Postpone the product launch' = hoãn ra mắt."},
            {"level": "A1", "transcript": "My job is to answer phone calls and help customers. I work at a call center.", "question": "Người nói làm công việc gì?", "options": ["Trả lời điện thoại, hỗ trợ khách hàng", "Bán hàng trực tiếp", "Giao hàng", "Lập trình viên"], "correctAnswer": 0, "explanation": "'Answer phone calls and help customers'."},
        ],
    },
    "food": {
        "vocabulary": [
            {"level": "A1", "question": '"Sour" nghĩa là gì?', "options": ["Chua", "Ngọt", "Cay", "Đắng"], "correctAnswer": 0, "explanation": "\"Sour\" là chua."},
            {"level": "B1", "question": '"To season a dish" nghĩa là gì?', "options": ["Nêm nếm món ăn", "Nấu chín món ăn", "Bày món ăn ra đĩa", "Bảo quản món ăn"], "correctAnswer": 0, "explanation": "\"Season\" là nêm nếm."},
            {"level": "A2", "question": '"Leftovers" nghĩa là gì?', "options": ["Đồ ăn thừa", "Món khai vị", "Món tráng miệng", "Nguyên liệu tươi"], "correctAnswer": 0, "explanation": "\"Leftovers\" là đồ ăn thừa."},
            {"level": "B2", "question": '"Ingredient" nghĩa là gì?', "options": ["Nguyên liệu", "Công thức nấu ăn", "Dụng cụ bếp", "Khẩu phần ăn"], "correctAnswer": 0, "explanation": "\"Ingredient\" là nguyên liệu."},
            {"level": "C1", "question": '"To garnish a dish" nghĩa là gì?', "options": ["Trang trí món ăn", "Ướp gia vị", "Hâm nóng lại", "Cắt nhỏ nguyên liệu"], "correctAnswer": 0, "explanation": "\"Garnish\" là trang trí món ăn."},
        ],
        "grammar": [
            {"level": "A2", "question": "There ___ some rice left in the pot.", "options": ["is", "are", "be", "were"], "correctAnswer": 0, "explanation": "\"Rice\" không đếm được, dùng \"is\"."},
            {"level": "B1", "question": "This soup tastes ___ than the one I made yesterday.", "options": ["good", "well", "better", "best"], "correctAnswer": 2, "explanation": "So sánh hơn: \"better\"."},
            {"level": "A2", "question": "How ___ sugar do you want in your coffee?", "options": ["much", "many", "lot", "few"], "correctAnswer": 0, "explanation": "\"Sugar\" không đếm được nên dùng \"much\"."},
            {"level": "B2", "question": "The cake ___ by the time the guests arrive.", "options": ["will bake", "will have been baked", "bakes", "baked"], "correctAnswer": 1, "explanation": "Tương lai hoàn thành bị động: \"will have been baked\"."},
            {"level": "B1", "question": "I've never ___ such delicious pho before.", "options": ["eat", "ate", "eaten", "eating"], "correctAnswer": 2, "explanation": "Hiện tại hoàn thành dùng phân từ hai: \"eaten\"."},
        ],
        "reading": [
            {"level": "A2", "question": "Phở thường được ăn vào bữa nào theo truyền thống?\n\nPho is a traditional Vietnamese noodle soup... It is usually eaten for breakfast.", "options": ["Bữa sáng", "Bữa trưa", "Bữa tối", "Bữa xế"], "correctAnswer": 0, "explanation": "'Usually eaten for breakfast'."},
            {"level": "B1", "question": "Vì sao người bán hàng rong thường chỉ bán một hoặc hai món?\n\nStreet food vendors often specialize in just one or two dishes, perfecting their recipe over years.", "options": ["Để hoàn thiện công thức món ăn theo thời gian", "Vì thiếu nguyên liệu", "Vì luật quy định", "Vì không đủ vốn"], "correctAnswer": 0, "explanation": "'Perfecting their recipe over years'."},
            {"level": "C1", "question": "Lên men mang lại lợi ích gì ngoài việc bảo quản?\n\nFermentation... enhances flavor and introduces beneficial bacteria that aid digestion.", "options": ["Tăng hương vị và có lợi cho tiêu hóa", "Làm món ăn đẹp mắt hơn", "Giảm giá thành sản phẩm", "Kéo dài thời gian nấu"], "correctAnswer": 0, "explanation": "Lên men tăng hương vị và có lợi cho tiêu hóa."},
            {"level": "B2", "question": "Điều gì đang thúc đẩy xu hướng ăn chay ở Việt Nam?\n\nVegetarianism is gaining popularity in Vietnam, influenced by health trends and Buddhist traditions.", "options": ["Xu hướng sức khỏe và truyền thống Phật giáo", "Giá thịt tăng cao", "Thiếu nguồn cung thịt", "Quy định của chính phủ"], "correctAnswer": 0, "explanation": "'Health trends and Buddhist traditions'."},
            {"level": "B1", "question": "Chuyên gia dinh dưỡng khuyên nên làm gì để có chế độ ăn lành mạnh hơn?\n\nNutritionists recommend filling half the plate with vegetables.", "options": ["Lấp đầy nửa đĩa ăn bằng rau củ", "Ăn nhiều tinh bột hơn", "Bỏ hoàn toàn chất đạm", "Chỉ ăn một bữa mỗi ngày"], "correctAnswer": 0, "explanation": "'Filling half the plate with vegetables'."},
        ],
        "listening": [
            {"level": "A2", "transcript": "Can I take your order? I'd like a bowl of pho and an iced coffee, please. No onions in the pho.", "question": "Khách hàng gọi món gì?", "options": ["Phở và cà phê đá", "Bún và trà đá", "Cơm và nước cam", "Phở và trà sữa"], "correctAnswer": 0, "explanation": "'A bowl of pho and an iced coffee'."},
            {"level": "A1", "transcript": "This dish is too spicy for me. Can you make it less spicy next time?", "question": "Người nói cảm thấy món ăn như thế nào?", "options": ["Quá cay", "Quá mặn", "Quá ngọt", "Quá nhạt"], "correctAnswer": 0, "explanation": "'Too spicy' = quá cay."},
            {"level": "B1", "transcript": "To make this dish, first marinate the chicken for thirty minutes, then stir-fry it with garlic and ginger over high heat.", "question": "Bước đầu tiên trong công thức là gì?", "options": ["Ướp gà trong ba mươi phút", "Xào tỏi và gừng", "Nấu ở lửa nhỏ", "Thêm nước sốt"], "correctAnswer": 0, "explanation": "'First marinate the chicken for thirty minutes'."},
            {"level": "B2", "transcript": "The restaurant is fully booked tonight, but we do have a table available for tomorrow evening at seven.", "question": "Nhà hàng còn bàn trống vào lúc nào?", "options": ["Bảy giờ tối mai", "Tối nay", "Trưa mai", "Không còn bàn trống"], "correctAnswer": 0, "explanation": "'A table available for tomorrow evening at seven'."},
            {"level": "A2", "transcript": "I'm allergic to peanuts. Does this dish contain any nuts?", "question": "Người nói dị ứng với gì?", "options": ["Đậu phộng", "Hải sản", "Sữa", "Trứng"], "correctAnswer": 0, "explanation": "'Allergic to peanuts' = dị ứng đậu phộng."},
        ],
    },
}

QUESTION_BANK.update(EXTRA_QUESTION_BANK)

TOPIC_ALIASES = {
    "family": "Gia đình & Bạn bè",
    "travel": "Du lịch",
    "work": "Công việc & Nghề nghiệp",
    "food": "Ẩm thực",
    **EXTRA_TOPIC_ALIASES,
}

AVAILABLE_TOPICS = list(QUESTION_BANK.keys())


def get_questions(topic: str, skill_type: str, count: int = 5) -> list:
    """Lấy câu hỏi từ question bank, shuffle và trả về `count` câu."""
    topic_key = topic.lower().replace(" ", "_")
    topic_data = QUESTION_BANK.get(topic_key)
    if not topic_data:
        return []

    skill_data = topic_data.get(skill_type, [])
    if not skill_data:
        # Fallback: trộn tất cả skill types cho topic đó
        for st in topic_data.values():
            skill_data.extend(st)

    random.shuffle(skill_data)
    selected = skill_data[:count]

    result = []
    for i, q in enumerate(selected):
        options = list(q["options"])
        correct = options[q["correctAnswer"]]
        random.shuffle(options)
        result.append({
            "id": f"bank_{topic_key}_{skill_type}_{i}",
            "question": q["question"],
            "options": options,
            "correctAnswer": correct,
            "explanation": q.get("explanation", ""),
            "transcript": q.get("transcript"),
            "level": q.get("level", "A2"),
        })
    return result


def get_available_topics() -> list:
    """Trả về danh sách chủ đề kèm tên tiếng Việt."""
    return [{"key": k, "label": TOPIC_ALIASES.get(k, k.capitalize())} for k in QUESTION_BANK]
