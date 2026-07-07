import 'package:flutter/material.dart';
import 'package:resqboxvendor/Utils/access_helper.dart';
import 'package:resqboxvendor/Utils/textstyles.dart';

class TeamMemberAccessWrapper extends StatelessWidget {
  final Widget child;
  final String featureName;

  const TeamMemberAccessWrapper({
    Key? key,
    required this.child,
    this.featureName = 'dashboard',
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: AccessHelper.isTeamMember(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        final isTeamMember = snapshot.data ?? false;

        if (isTeamMember) {
          // Show access denied message for team members
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.lock_outline, size: 80, color: Colors.grey),
                  SizedBox(height: 20),
                  Text(
                    "You Don't Have Access",
                    style: AppTextStyles.size20SemiBold,
                  ),
                  SizedBox(height: 10),
                  Text(
                    "This feature is only available for kitchen owners",
                    style: AppTextStyles.size14Medium.copyWith(
                      color: Colors.grey,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }

        // Show normal content for kitchen owners
        return child;
      },
    );
  }
}
