import 'package:flutter/material.dart';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../constants.dart';

final _firestore = Firestore.instance;

class ChatScreen extends StatefulWidget {
  static const routeName = 'chat';
  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final messageTextController = TextEditingController();
  final _auth = FirebaseAuth.instance;
  FirebaseUser loggedInUser;
  String _messageText;

  @override
  void initState() {
    super.initState();
    getCurrentUser();
  }

  void getCurrentUser() async {
    try {
      final user = await _auth.currentUser();

      if (user != null) {
        loggedInUser = user;
      }
    } catch (e) {
      print(e);
    }
  }

//  void getMessages() async {
//    final messages = await _firestore.collection('messages').getDocuments();
//    for (var message in messages.documents) {
//      print(message.data);
//    }
//  }

  void messagesStream() async {
    await for (var snapshot in _firestore.collection('messages').snapshots()) {
      for (var message in snapshot.documents) {
        print(message.data);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: null,
        actions: <Widget>[
          IconButton(
              icon: Icon(Icons.close),
              onPressed: () {
                messagesStream();
//                _auth.signOut();
//                Navigator.pop(context);
              }),
        ],
        title: Text('⚡️Chat'),
        backgroundColor: Colors.lightBlueAccent,
      ),
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            MessagesStream(),
            Container(
              decoration: kMessageContainerDecoration,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  Expanded(
                    child: TextField(
                      controller: messageTextController,
                      onChanged: (value) {
                        _messageText = value;
                      },
                      decoration: kMessageTextFieldDecoration,
                    ),
                  ),
                  FlatButton(
                    onPressed: () {
                      messageTextController.clear();
                      _firestore.collection('messages').add({
                        'text': _messageText,
                        'sender': loggedInUser.email,
                      });
                    },
                    child: Text('Send', style: kSendButtonTextStyle),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class MessagesStream extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
        stream: _firestore.collection('messages').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            final messages = snapshot.data.documents;
            List<MessageBubble> msgBubbles = [];
            for (var message in messages) {
              final msgText = message.data['text'];
              final msgSender = message.data['sender'];
              final msgBubble = MessageBubble(
                sender: msgSender,
                text: msgText,
              );
              msgBubbles.add(msgBubble);
            }
            return Expanded(
              child: ListView(
                padding: EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 20,
                ),
                children: msgBubbles,
              ),
            );
          } else {
            return CircularProgressIndicator();
          }
        });
  }
}

class MessageBubble extends StatelessWidget {
  final String sender;
  final String text;

  MessageBubble({this.sender, this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(10.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: <Widget>[
          Text(
            sender,
            style: TextStyle(fontSize: 14, color: Colors.black54),
          ),
          Material(
              borderRadius: BorderRadius.circular(30),
              elevation: 5,
              color: Colors.lightBlueAccent,
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                child: Text(
                  text,
                  style: TextStyle(fontSize: 18, color: Colors.white),
                ),
              )),
        ],
      ),
    );
  }
}
