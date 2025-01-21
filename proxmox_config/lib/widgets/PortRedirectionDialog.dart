import 'package:flutter/material.dart';
import 'package:proxmox_config/models/RedirectionData.dart';
import 'package:proxmox_config/widgets/CustomButton.dart';
import 'package:proxmox_config/widgets/ListWithTitle.dart';
import 'package:proxmox_config/utils/SSHUtils.dart';
import 'package:proxmox_config/widgets/PortRedirectionDisplay.dart';

class PortRedirectionDialog extends StatefulWidget {
  const PortRedirectionDialog({Key? key}) : super(key: key);

  @override
  State<PortRedirectionDialog> createState() => _PortRedirectionDialogState();
}

class _PortRedirectionDialogState extends State<PortRedirectionDialog> {

  List<RedirectionData>? redirections;

  @override
  void initState() {
    super.initState();
    _loadRedirections();
  }

  void _loadRedirections() async {
    redirections = await SSHUtils.getRedirections();
    setState(() {});
  }

  void _saveRedirections() async {
    await SSHUtils.saveRedirections(redirections!);
  }

  void onChanged(RedirectionData newdata,RedirectionData previusData) {
    previusData.dport = newdata.dport;
    previusData.tport = newdata.tport;
  }

  void addRedirection(RedirectionData data) {
    redirections!.add(data);
    setState(() {});
  }

  void deleteRedirection(RedirectionData data) {
    print('Deleting: ${data.dport}, ${data.tport}');
    setState(() {
      redirections!.remove(data);
    });
  }

  List<Widget> getRedirections() {
    return List.generate(redirections!.length, (index) {
      final e = redirections![index];
      return Row(
        key: ValueKey(e), // Key to uniquely identify the widget
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          PortRedirectionDisplay(
            onChanged: (data) => onChanged(data, e),
            initialData: e,
          ),
          CustomButton(
            text: 'Delete',
            color: Colors.red,
            onPressed: () => deleteRedirection(e),
          ),
        ],
      );
    });
  }



  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        padding: const EdgeInsets.all(16),
        child:Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
          ListWithTitle(title: "Port Redirections", items: 
            redirections == null ? [
              const Center(child: CircularProgressIndicator()),
            ] : getRedirections()
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              CustomButton(
                text: 'Cancel',
                color: Colors.blue,
                onPressed: () {
                  Navigator.pop(context);
                },
              ),
              CustomButton(
                text: 'Add',
                color: Colors.blue,
                onPressed: () => {
                  addRedirection(new RedirectionData(dport: null, tport: null))
                },
              ),
              CustomButton(
                onPressed: () {
                  _saveRedirections();
                  Navigator.pop(context);
                },
                text: 'Save',
                color: Colors.blue,
              ),
            ],
          )
        ],
        ) 
      )
    );
  }
}