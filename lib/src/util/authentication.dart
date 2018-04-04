part of chatapp;

final googleSignIn = new GoogleSignIn();
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