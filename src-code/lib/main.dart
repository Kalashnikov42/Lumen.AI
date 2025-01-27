import 'package:flutter/material.dart';
import 'three_bounce.dart'; 
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() async {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData.dark().copyWith(
        cardTheme: const CardTheme(
          color: Colors.black,
        ),
        textTheme: ThemeData.dark().textTheme.apply(fontFamily: 'Roboto'),
        scaffoldBackgroundColor: Colors.black,
        primaryColor: Colors.white,
      ),
      home: const ChatPage(),
    );
  }
}

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  TextEditingController controller = TextEditingController();
  List<String> listDatas = [];
  ValueNotifier<bool> isLoading = ValueNotifier(false);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(50),
        child: AppBar(
          backgroundColor: Colors.black,
          elevation: 0,
          title: const Text(
            'Lumen.ai',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.topLeft,
            radius: 1.5,
            colors: [
              Colors.black,
              Color(0xFF1C1C1C),
            ],
          ),
        ),
        child: Column(
          children: [
            listDatas.isEmpty
                ? Expanded(
                    child: Center(
                      child: ColorFiltered(
                        colorFilter: ColorFilter.mode(
                          Colors.white,
                          BlendMode.srcIn,
                        ),
                        child: Image.asset(
                          'assets/background_image.png',
                          fit: BoxFit.cover,
                          width: MediaQuery.of(context).size.width * 0.6,
                        ),
                      ),
                    ),
                  )
                : Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                      itemCount: listDatas.length,
                      itemBuilder: (BuildContext context, int index) {
                        final isUserMessage = index.isOdd;
                        return Align(
                          alignment: isUserMessage ? Alignment.centerLeft : Alignment.centerRight,
                          child: Row(
                            mainAxisAlignment:
                                isUserMessage ? MainAxisAlignment.start : MainAxisAlignment.end,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              if (isUserMessage)
                                const CircleAvatar(
                                  backgroundColor: Colors.white,
                                  child: Icon(Icons.android, color: Colors.black),
                                ),
                              if (!isUserMessage) const SizedBox(width: 8),
                              Flexible(
                                child: Container(
                                  padding: const EdgeInsets.all(12),
                                  margin: const EdgeInsets.symmetric(vertical: 6),
                                  decoration: BoxDecoration(
                                    color: isUserMessage ? Colors.grey[800] : Colors.grey[800],
                                    borderRadius: BorderRadius.circular(15),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.5),
                                        blurRadius: 8,
                                        offset: const Offset(2, 2),
                                      ),
                                    ],
                                  ),
                                  child: Text(
                                    listDatas[index],
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium!
                                        .copyWith(color: Colors.white),
                                    softWrap: true,
                                    overflow: TextOverflow.visible,
                                  ),
                                ),
                              ),
                              if (!isUserMessage)
                                const CircleAvatar(
                                  backgroundColor: Colors.white,
                                  child: Icon(Icons.person, color: Colors.black),
                                ),
                              if (isUserMessage) const SizedBox(width: 4),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
            ValueListenableBuilder(
              valueListenable: isLoading,
              builder: (BuildContext context, dynamic value, Widget? child) {
                if (!value) {
                  return const SizedBox();
                }
                return const SpinKitThreeBounce(
                  color: Colors.white,
                  size: 30,
                );
              },
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Container(
                width: 600,
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: controller,
                        onEditingComplete: () async {
                          _searchContent();
                        },
                        decoration: InputDecoration(
                          hintText: "Enter a Prompt...",
                          hintStyle: const TextStyle(color: Colors.grey),
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.all(12),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(color: Colors.white),
                          ),
                          prefixIcon:
                              const Icon(Icons.message, color: Colors.black),
                        ),
                        style: const TextStyle(color: Colors.black),
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () async {
                        await _searchContent();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        shape: const CircleBorder(
                            side: BorderSide(color: Colors.grey, width: 2.0)),
                        padding: const EdgeInsets.all(12),
                      ),
                      child: const Icon(Icons.send, color: Colors.black),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _searchContent() async {
    if (controller.text.isNotEmpty) {
      final userMessage = controller.text;
      listDatas.add(userMessage);
      controller.clear();

      isLoading.value = true;

      try {
        final response = await http.post(
          Uri.parse('https://webhook.botpress.cloud/e7acefe0-8d74-4b4b-9a01-87eea9ca7eee'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer bp_pat_GeWPSfNeYCA7d0s0cAx8coT2YIZ1LnW2DiZ7',
          },
          body: json.encode({
            "userId": "remoteUserId",
            "messageId": "remoteMessageId",
            "conversationId": "remoteConversationId",
            "type": "text",
            "text": userMessage,
            "payload": {
              "foo": "bar",
              "user": {"userName": "Robert"}
            },
          }),
        );

        if (response.statusCode == 200) {
          final webhookResponse = await http.get(
            Uri.parse('https://wh41ba0ebd90269ed2de.free.beeceptor.com'),
          );

          if (webhookResponse.statusCode == 200) {
            final responseData = json.decode(webhookResponse.body);
            final vardummy = responseData['body'];
            print('HAHAHAHAHA $vardummy');
            final botReply = responseData['body'];
            listDatas.add(botReply);
          } else {
            listDatas.add("Error: Unable to fetch bot reply from webhook.");
          }
        } else {
          listDatas.add("Error: Unable to send user message.");
        }
      } catch (e) {
        listDatas.add("Error: ${e.toString()}");
      }

      isLoading.value = false;
      setState(() {});
    }
  }
}
