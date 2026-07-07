import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'package:provider/provider.dart';
import 'package:resqboxvendor/Controller/TeamController.dart';
import 'package:resqboxvendor/Models/team_member_model.dart';
import 'package:resqboxvendor/Screens/Account/add_team.dart';
import 'package:resqboxvendor/Utils/colors.dart';
import 'package:resqboxvendor/Utils/custom_appbar.dart';
import 'package:resqboxvendor/Utils/custom_border_btn.dart';
import 'package:resqboxvendor/Utils/images.dart';
import 'package:resqboxvendor/Utils/navigations.dart';
import 'package:resqboxvendor/Utils/textstyles.dart';

class MyTeam extends StatefulWidget {
  const MyTeam({super.key});

  @override
  State<MyTeam> createState() => _MyTeamState();
}

class _MyTeamState extends State<MyTeam> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final controller = Provider.of<TeamController>(context, listen: false);
      controller.getTeamMembers();
    });
  }

  void _showDeleteConfirmation(TeamMember member) {
    showCupertinoModalPopup<void>(
      context: context,
      builder: (BuildContext context) => CupertinoAlertDialog(
        title: Text(
          'Delete Team Member',
          style: AppTextStyles.size14Medium.copyWith(
            color: AppColors.mainAppColr,
          ),
        ),
        content: Text(
          'Are You Sure, You Want To Delete ${member.fullName}?',
          style: AppTextStyles.size14Medium,
        ),
        actions: <CupertinoDialogAction>[
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () {
              Navigator.pop(context, false);
            },
            child: Text(
              "No",
              style: AppTextStyles.size14Regular.copyWith(
                color: AppColors.mainAppColr,
              ),
            ),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () async {
              Navigator.pop(context, true);
              final controller = Provider.of<TeamController>(
                context,
                listen: false,
              );
              await controller.deleteTeamMember(member.id!);
            },
            child: Text(
              "Yes",
              style: AppTextStyles.size14Regular.copyWith(
                color: AppColors.green26A860,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: CustomAppBar(
        title: "Team",
        isLeading: true,
        backTap: () {
          NavigateTo().backPage();
        },
      ),
      body: Consumer<TeamController>(
        builder: (context, controller, child) {
          if (controller.isLoadingTeamMembers) {
            return const Center(child: CircularProgressIndicator());
          }
          return controller.teamMembers.isEmpty
              ? _buildEmptyState()
              : _buildTeamList(controller);
        },
      ),
      bottomNavigationBar: Consumer<TeamController>(
        builder: (context, controller, child) {
          if (controller.teamMembers.isEmpty) {
            return const SizedBox.shrink();
          }
          return SafeArea(
            child: Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(color: Colors.white),
              child: CustomRectBtn(
                width: MediaQuery.of(context).size.width / 1.5,
                onTap: () {
                  NavigateTo().nextPage(child: AddTeamMember());
                },
                height: 49,
                borderRadius: 25,
                leading: Center(
                  child: Text(
                    "Add Team member",
                    style: AppTextStyles.size16SemiBold.copyWith(
                      color: Colors.white,
                    ),
                  ),
                ),
                color: const Color(0xffF47923),
                borderColor: const Color(0xffF47923),
                textColor: Colors.white,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(60),
            ),
            child: Center(
              child: Image.asset(
                AppImages.newTeamIcon,
                width: 80,
                height: 80,
                fit: BoxFit.contain,
              ),
            ),
          ),

          const SizedBox(height: 24),
          // Title
          Text("Build Your Team", style: AppTextStyles.size18SemiBold),
          const SizedBox(height: 12),
          // Description
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              "Add people who can help manage\norders and daily operations.",
              textAlign: TextAlign.center,
              style: AppTextStyles.size16Medium.copyWith(
                color: Color(0xff777777),
              ),
            ),
          ),
          Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: CustomRectBtn(
                width: MediaQuery.of(context).size.width / 1.5,
                onTap: () {
                  NavigateTo().nextPage(child: AddTeamMember());
                },
                height: 49,
                borderRadius: 25,
                leading: Center(
                  child: Text(
                    "Add Team member",
                    style: AppTextStyles.size16SemiBold.copyWith(
                      color: Colors.white,
                    ),
                  ),
                ),
                color: const Color(0xffF47923),
                borderColor: const Color(0xffF47923),
                textColor: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTeamList(TeamController controller) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: ListView.separated(
        padding: const EdgeInsets.only(
          bottom: 100,
        ), // Space for bottom navigation bar
        itemCount: controller.teamMembers.length,
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final member = controller.teamMembers[index];
          final profileImageUrl =
              member.profilePhoto != null && member.profilePhoto!.isNotEmpty
              ? '${member.profilePhoto}'
              : null;
          final firstLetter = member.fullName.isNotEmpty
              ? member.fullName[0].toUpperCase()
              : '?';

          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Color(0xffEAEAEA)),
            ),
            child: Stack(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Profile Image
                    CircleAvatar(
                      radius: 35,
                      backgroundColor: const Color(0xffF1913D).withOpacity(0.1),
                      child: profileImageUrl != null
                          ? ClipOval(
                              child: Image.network(
                                profileImageUrl,
                                width: 70,
                                height: 70,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Center(
                                    child: Text(
                                      firstLetter,
                                      style: AppTextStyles.size16SemiBold
                                          .copyWith(
                                            fontSize: 16,
                                            color: Colors.black87,
                                          ),
                                    ),
                                  );
                                },
                                loadingBuilder:
                                    (context, child, loadingProgress) {
                                      if (loadingProgress == null) return child;
                                      return Center(
                                        child: CircularProgressIndicator(
                                          value:
                                              loadingProgress
                                                      .expectedTotalBytes !=
                                                  null
                                              ? loadingProgress
                                                        .cumulativeBytesLoaded /
                                                    loadingProgress
                                                        .expectedTotalBytes!
                                              : null,
                                          strokeWidth: 2,
                                        ),
                                      );
                                    },
                              ),
                            )
                          : Center(
                              child: Text(
                                firstLetter,
                                style: AppTextStyles.size16SemiBold.copyWith(
                                  fontSize: 16,
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            member.fullName,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.size16Medium.copyWith(
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            member.email ?? "",
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.size14Regular.copyWith(
                              color: const Color(0xff00D341),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                Positioned(
                  top: 0,
                  right: 0,
                  child: PopupMenuButton<String>(
                    color: Colors.white,
                    icon: const Icon(Icons.more_horiz_outlined),
                    onSelected: (value) {
                      if (value == 'edit') {
                        final controller = Provider.of<TeamController>(
                          context,
                          listen: false,
                        );
                        controller.loadTeamMemberForEditing(member);
                        NavigateTo().nextPage(child: AddTeamMember());
                      } else if (value == 'delete') {
                        _showDeleteConfirmation(member);
                      }
                    },
                    itemBuilder: (BuildContext context) => [
                      const PopupMenuItem<String>(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit, size: 20),
                            SizedBox(width: 8),
                            Text('Edit'),
                          ],
                        ),
                      ),
                      const PopupMenuItem<String>(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, size: 20, color: Colors.red),
                            SizedBox(width: 8),
                            Text('Delete', style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
