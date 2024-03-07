import 'package:flutter/material.dart';
import 'package:mobile/pages/add_hub_page2.dart';

class AddHubPage1 extends StatelessWidget {
  const AddHubPage1({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('Find IoT Hub'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Pairing 버튼을 길게 눌러 파란색 LED가 빠르게 점등할 수 있도록 해 주세요'),
            const SizedBox(height: 20,),
            ElevatedButton(
              onPressed: (){
                Navigator.push(context,
                    MaterialPageRoute(builder: (context) {
                      return const AddHubPage2();
                    }));
              },//findHub,
              child: const Text('다음 단계로')
            )
          ],
        )
      )
    );
  }
}
