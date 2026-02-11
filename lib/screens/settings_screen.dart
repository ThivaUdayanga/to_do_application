import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../widgets/int_stepper_field.dart';
import '../controller/settings_controller.dart';

class SettingsScreen extends StatefulWidget {

  final int ownerId;
  const SettingsScreen({super.key, required this.ownerId});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  //final _formKey = GlobalKey<FormState>();

  int _deleteBlockTime = 24;
  int _maxTasksPerDay = 2;

  bool _loadedOnce = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (!_loadedOnce) {
      _loadedOnce = true;

      Future.microtask(() async {
        final controller = context.read<SettingsController>();
        await controller.loadSettings(widget.ownerId);

        if (!mounted) return;

        setState(() {
          _deleteBlockTime = controller.deleteBlockTime;
          _maxTasksPerDay = controller.maxTasksPerDay;
        });
      });
    }
  }

  void _showErrorIfAny(SettingsController controller) {
    final msg = controller.errorMessage;
    if (msg == null) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: Colors.red),
      );
      controller.clearError();
    });
  }

  Future<void> _save() async {
    final controller = context.read<SettingsController>();

    final ok = await controller.saveSettings(
      ownerId: widget.ownerId,
      deleteBlockTime: _deleteBlockTime,
      maxTasksPerDay: _maxTasksPerDay,
    );

    if (!mounted) return;

    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Settings saved'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      _showErrorIfAny(controller);
    }
  }

  void _cancelReset() {
    setState(() {
      _deleteBlockTime = 24;
      _maxTasksPerDay = 2;
    });
  }


  // @override
  // void initState() {
  //   super.initState();
  //   _deleteBlockTimeController = TextEditingController(text: '24');
  //   _maxTasksPerDayController = TextEditingController(text: '2');
  // }

  // @override
  // void dispose() {
  //   _deleteBlockTimeController.dispose();
  //   _maxTasksPerDayController.dispose();
  //   super.dispose();
  // }

//   void _save() {
//     //if (!_formKey.currentState!.validate()) return;
//
//     final int deleteBlockTime = _deleteBlockTime;
//     final int maxTasksPerDay = _maxTasksPerDay;
//
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Text(
//           'Saved: delete block time = $deleteBlockTime, max tasks/day = $maxTasksPerDay',
//         ),
//         backgroundColor: Colors.green,
//       ),
//     );
//   }

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsController>(
      builder:(context, controller, child){
        _showErrorIfAny(controller);
        return Scaffold(
          backgroundColor: Colors.grey[100],
          appBar: AppBar(
            title: const Text('Settings'),
            backgroundColor: Colors.deepPurple,
            foregroundColor: Colors.white,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          body:controller.isLoading
              ? const Center(child: CircularProgressIndicator())
              :Padding(
                padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      IntStepperField(
                        label: 'Delete block time (hours)',
                        value: _deleteBlockTime,
                        min: 1,
                        max: 72,
                        onDecrement: () => setState(() => _deleteBlockTime--),
                        onIncrement: () => setState(() => _deleteBlockTime++),
                      ),
                      const SizedBox(height: 16),
                      IntStepperField(
                        label: 'Per day max tasks',
                        value: _maxTasksPerDay,
                        min: 1,
                        max: 50,
                        onDecrement: () => setState(() => _maxTasksPerDay--),
                        onIncrement: () => setState(() => _maxTasksPerDay++),
                      ),
                      const SizedBox(height: 24),
                      Column(
                        children: [
                          SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: ElevatedButton(
                              onPressed: controller.isLoading ? null : _save,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.deepPurple,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text('Save'),
                            ),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: OutlinedButton(
                              onPressed: _cancelReset,
                              style: OutlinedButton.styleFrom(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text('Cancel'),
                            ),

                          ),
                        ],
                      ),

                    ],
                  ),
                ),

        );
      }
    );
  }
}


