import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'dart:async';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_database/ui/firebase_animated_list.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:math';
import 'dart:io';

// Firebase
final googleSignIn = new GoogleSignIn();
final analytics = new FirebaseAnalytics();
final auth = FirebaseAuth.instance;

// Sign in
Future<Null> _ensureLoggedIn() async {
  GoogleSignInAccount user = googleSignIn.currentUser;
  if(user == null) {
    user = await googleSignIn.signInSilently();
  }
  if(user == null) {
    await googleSignIn.signIn();
    analytics.logLogin();
  }
  if(await auth.currentUser() == null) {
    GoogleSignInAuthentication credentials = await googleSignIn.currentUser.authentication;
    await auth.signInWithGoogle(
      idToken: credentials.idToken,
      accessToken: credentials.accessToken,
    );
  }
}

// Main
void main() {
  runApp(new MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return new MaterialApp(
      title: 'Chit Chat',
      home: new ChatScreen(),
      theme: defaultTargetPlatform == TargetPlatform.iOS ? iOSTheme : androidTheme,
    );
  }
}

// Themes
final ThemeData iOSTheme = new ThemeData(
  brightness: Brightness.dark,
  accentColor: Colors.grey[300],
);

final ThemeData androidTheme = new ThemeData(
  primarySwatch: Colors.purple,
  accentColor: Colors.orangeAccent[400],
);


// Design
class ChatScreen extends StatefulWidget {
  @override
  State createState() => new ChatScreenState();
}

class ChatScreenState extends State<ChatScreen> {
  final TextEditingController _textController = new TextEditingController();
  bool _isComposing = false;
  
  // Firebase database
  final reference = FirebaseDatabase.instance.reference().child('messages');

  // Setup
  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      appBar: new AppBar(
        title: new Text('Chit Chat'),
        elevation: Theme.of(context).platform == TargetPlatform.iOS ? 0.0 : 4.0,
      ),
      body: new Container(
        child: new Column(
          children: <Widget>[
            new Flexible(
              child: new FirebaseAnimatedList(
                query: reference,
                sort: (a, b) => b.key.compareTo(a.key),
                padding: new EdgeInsets.all(8.0),
                reverse: true,
                itemBuilder: (_, DataSnapshot snapshot, Animation<double> animation, int index) {
                  return new ChatMessage(
                    snapshot: snapshot,
                    animation: animation
                  );
                },
              ),
            ),
            new Divider(height: 1.0),
            new Container(
              decoration: new BoxDecoration(
                color: Theme.of(context).cardColor
              ),
              child: _buildTextComposer(),
            ),
          ],
        ),
      ),
    );
  }

  // Widgets
  Widget _buildTextComposer() {
    return new IconTheme(
      data: new IconThemeData(color: Theme.of(context).accentColor),
      child: new Container(
        margin: const EdgeInsets.symmetric(horizontal: 8.0),
        child: new Row(
          children: <Widget>[
            new Container(
              margin: new EdgeInsets.symmetric(horizontal: 4.0),
              child: new IconButton(
                icon: new Icon(Icons.photo_camera),
                onPressed: () async {
                  await _ensureLoggedIn();
                  File imageFile = await ImagePicker.pickImage(source: ImageSource.gallery);

                  // Generate a random name
                  int random = new Random().nextInt(10000000);
                  StorageReference ref = FirebaseStorage.instance.ref().child("image_$random.jpg");

                  // Upload image
                  StorageUploadTask uploadTask = ref.put(imageFile);
                  Uri downloadUrl = (await uploadTask.future).downloadUrl;

                  // Send image
                  _sendMessage(imageUrl: downloadUrl.toString());
                },
              ),
            ),
            new Flexible(
              child: new TextField(
                controller: _textController,
                onChanged: (String text) {
                  setState(() {
                    _isComposing = text.length > 0;
                  });
                },
                onSubmitted: _handleSubmitted,
                decoration: new InputDecoration.collapsed(
                  hintText: "Send a message",
                ),
              ),
            ),
            new Container(
              margin: new EdgeInsets.symmetric(horizontal: 4.0),
              child: Theme.of(context).platform == TargetPlatform.iOS ?
              new CupertinoButton(
                child: new Text("Send"),
                onPressed: _isComposing ? () => _handleSubmitted(_textController.text) : null,
              ) :
              new IconButton(
                icon: new Icon(Icons.send),
                onPressed: _isComposing ? () => _handleSubmitted(_textController.text) : null,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Methods
  Future<Null> _handleSubmitted(String text) async {
    _textController.clear();

    // Disable isComposing
    setState(() {
      _isComposing = false;
    });
    await _ensureLoggedIn();
    _sendMessage(text: text);
  }

  void _sendMessage({String text, String imageUrl}) {
    reference.push().set({
      'text': text,
      'imageUrl': imageUrl,
      'senderName': googleSignIn.currentUser.displayName,
      'senderPhotoUrl': googleSignIn.currentUser.photoUrl,
    });

    if(imageUrl == null)
      analytics.logEvent(name: 'send_message');
    else
      analytics.logEvent(name: 'send_photo_message');
  }
}

class ChatMessage extends StatelessWidget {
  // Members
  final DataSnapshot snapshot;
  final Animation animation;

  // Constructor
  ChatMessage({this.snapshot, this.animation});
  
  @override
  Widget build(BuildContext context) {
    return new SizeTransition(
      sizeFactor: new CurvedAnimation(
        parent: animation, curve: Curves.linear
      ),
      axisAlignment: 0.0,
      child: new Container(
        margin: const EdgeInsets.symmetric(vertical: 10.0),
        child: new Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            new Container(
              margin: const EdgeInsets.only(right: 16.0),
              child: new CircleAvatar(
                backgroundImage: new NetworkImage(snapshot.value['senderPhotoUrl']),
              ),
            ),
            new Expanded(
              child: new Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  new Text(
                    snapshot.value['senderName'],
                    style: Theme.of(context).textTheme.subhead
                  ),
                  new Container(
                    margin: const EdgeInsets.only(top: 5.0),
                    child: snapshot.value['imageUrl'] != null ?
                      new Image.network(
                        snapshot.value['imageUrl'],
                        width: 250.0,
                      ) :
                      new Text(snapshot.value['text']),
                  )
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}