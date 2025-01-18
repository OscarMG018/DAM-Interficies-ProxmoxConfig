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
            ] : 
            redirections!.map((e) => PortRedirectionDisplay(onChanged: (data) => onChanged(data,e), initialData: e)).toList()
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
                onPressed: () {
                  _saveRedirections();
                  //Navigator.pop(context);
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