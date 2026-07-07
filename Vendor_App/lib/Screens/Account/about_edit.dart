import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:resqboxvendor/Controller/KitchenProfileController.dart';
import 'package:resqboxvendor/Utils/custom_appbar.dart';
import 'package:resqboxvendor/Utils/custom_border_btn.dart';
import 'package:resqboxvendor/Utils/navigations.dart';
import 'package:resqboxvendor/Utils/textstyles.dart';

class AboutEditScreen extends StatefulWidget {
  const AboutEditScreen({super.key});

  @override
  State<AboutEditScreen> createState() => _AboutEditScreenState();
}

class _AboutEditScreenState extends State<AboutEditScreen> {
  final TextEditingController _descriptionController = TextEditingController();
  final int _maxCharacters = 200;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadCurrentData();
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  void _loadCurrentData() {
    final controller = Provider.of<KitchenProfileController>(
      context,
      listen: false,
    );
    final kitchen = controller.kitchenDetails;
    _descriptionController.text = kitchen?.description ?? '';
  }

  int get _remainingCharacters =>
      _maxCharacters - _descriptionController.text.length;

  Future<void> _saveChanges() async {
    setState(() {
      _isLoading = true;
    });

    final controller = Provider.of<KitchenProfileController>(
      context,
      listen: false,
    );

    final success = await controller.updateKitchen(
      description: _descriptionController.text.trim(),
    );

    setState(() {
      _isLoading = false;
    });

    if (success && mounted) {
      NavigateTo().backPage();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xfff3f4f8),
      appBar: CustomAppBar(
        title: "Edit Info",
        isLeading: true,
        backTap: () {
          NavigateTo().backPage();
        },
      ),
      body: Padding(
        padding: const EdgeInsets.all(36.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Text(
              "About",
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.size14Medium,
            ),
            SizedBox(height: 14),
            TextFormField(
              controller: _descriptionController,
              minLines: 6,
              maxLines: 15,
              maxLength: _maxCharacters,
              onChanged: (value) {
                setState(() {});
              },
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white,
                hintText: "Enter description...",
                counterText: "", // Hide default counter
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Color(0xffFE5E00)),
                ),
              ),
            ),
            SizedBox(height: 20),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                "${_descriptionController.text.length}/$_maxCharacters",
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.size14Regular.copyWith(
                  color: _remainingCharacters < 20
                      ? Color(0xffEC4F3A)
                      : Color(0xff777777),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Padding(
        padding: EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: CustomRectBtn(
                width: MediaQuery.of(context).size.width * 0.45,
                onTap: () => NavigateTo().backPage(),
                height: 49,
                borderRadius: 25,
                leading: Center(
                  child: Text(
                    "Cancel",
                    style: AppTextStyles.size16SemiBold.copyWith(
                      color: Colors.black,
                    ),
                  ),
                ),
                color: Colors.white,
                borderColor: Color(0xffF1913D),
                textColor: Colors.black,
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: CustomRectBtn(
                onTap: _isLoading
                    ? () {}
                    : () {
                        _saveChanges();
                      },
                height: 49,
                width: MediaQuery.of(context).size.width * 0.45,
                borderRadius: 25,
                leading: Center(
                  child: _isLoading
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : Text(
                          "Save Changes",
                          style: AppTextStyles.size16SemiBold.copyWith(
                            color: Colors.white,
                          ),
                        ),
                ),
                color: Color(0xffF1913D),
                borderColor: Color(0xffF1913D),
                textColor: Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
