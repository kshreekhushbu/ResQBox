class PushNotificationsModel {
  String? title;
  String? body;

  PushNotificationsModel({this.title, this.body});

  PushNotificationsModel.fromJson(Map<String, dynamic> json) {
    title = json['title'];
    body = json['body'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['title'] = title;
    data['body'] = body;
    return data;
  }
}
