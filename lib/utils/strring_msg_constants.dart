class MessageText {
  static const String welcome_Message =
      "Hi, I am Drishti, your personal assistant." +
          " I can describe anything which you would like to see.";

  static const String ask_Name =
      "Before we start, please tells your name,and I’ll be happy to assist you right away!";

  static const String ask_Name_repeat = "Please tell your name,I am listening";

  static const String ask_start_repeat =
      "When your're ready, please say start,I am listening";

  static String getPersonalMessage(String name) {
    return "Okay cool!,$name, when your're ready, please say start, and the app will start right away ";
  }

  static const String app_start_messege =
      "I am fully set. Say the command, Take a picture. and I will take a picture and will describe it to you. If you want to stop, then say, Drishti stop, I will close the app";

  static const String app_image_error =
      "I am not able to describe your image right now, Please try again later";
}
