class TeamMemberResponse {
  int? status;
  String? message;
  List<TeamMember>? members;

  TeamMemberResponse({this.status, this.message, this.members});

  factory TeamMemberResponse.fromJson(Map<String, dynamic> json) =>
      TeamMemberResponse(
        status: json["status"],
        message: json["message"],
        members: json["members"] == null
            ? []
            : List<TeamMember>.from(
                json["members"].map((x) => TeamMember.fromJson(x))),
      );

  Map<String, dynamic> toJson() => {
        "status": status,
        "message": message,
        "members": members == null
            ? []
            : List<dynamic>.from(members!.map((x) => x.toJson())),
      };
}

class TeamMemberDetailResponse {
  int? status;
  String? message;
  TeamMember? member;

  TeamMemberDetailResponse({this.status, this.message, this.member});

  factory TeamMemberDetailResponse.fromJson(Map<String, dynamic> json) =>
      TeamMemberDetailResponse(
        status: json["status"],
        message: json["message"],
        member: json["member"] == null
            ? null
            : TeamMember.fromJson(json["member"]),
      );

  Map<String, dynamic> toJson() => {
        "status": status,
        "message": message,
        "member": member?.toJson(),
      };
}

class TeamMember {
  int? id;
  int? kitchenId;
  String? firstName;
  String? lastName;
  String? email;
  String? phoneNumber;
  String? username;
  String? password; // Hashed password from API
  String? profilePhoto;
  int? isActive;
  String? createdAt;
  String? updatedAt;

  TeamMember({
    this.id,
    this.kitchenId,
    this.firstName,
    this.lastName,
    this.email,
    this.phoneNumber,
    this.username,
    this.password,
    this.profilePhoto,
    this.isActive,
    this.createdAt,
    this.updatedAt,
  });

  factory TeamMember.fromJson(Map<String, dynamic> json) => TeamMember(
        id: json["id"],
        kitchenId: json["kitchenId"],
        firstName: json["firstName"],
        lastName: json["lastName"],
        email: json["email"],
        phoneNumber: json["phoneNumber"],
        username: json["username"],
        password: json["password"],
        profilePhoto: json["profilePhoto"],
        isActive: json["isActive"],
        createdAt: json["createdAt"],
        updatedAt: json["updatedAt"],
      );

  Map<String, dynamic> toJson() => {
        "id": id,
        "kitchenId": kitchenId,
        "firstName": firstName,
        "lastName": lastName,
        "email": email,
        "phoneNumber": phoneNumber,
        "username": username,
        "password": password,
        "profilePhoto": profilePhoto,
        "isActive": isActive,
        "createdAt": createdAt,
        "updatedAt": updatedAt,
      };

  String get fullName => "${firstName ?? ''} ${lastName ?? ''}".trim();
}

