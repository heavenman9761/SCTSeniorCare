import 'package:flutter/material.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  late Color myColor;
  late Size mediaSize;
  TextEditingController emailController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  bool rememberUser = false;
  bool autoLogin = false;

  @override
  Widget build(BuildContext context) {
    myColor = Theme.of(context).primaryColor;
    mediaSize = MediaQuery.of(context).size;
    return Container(
      decoration: BoxDecoration(
        color: myColor,
        image: DecorationImage(
          image: const AssetImage("assets/images/bg.png"),
          fit: BoxFit.cover,
          colorFilter:
          ColorFilter.mode(myColor.withOpacity(0.2), BlendMode.dstATop),
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Stack(children: [
          Positioned(top: 50, child: _buildTop()),
          Positioned(bottom: 0, child: _buildBottom()),
        ]),
      ),
    );
  }

  Widget _buildTop() {
    return SizedBox(
      width: mediaSize.width,
      child: const Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.home_work_outlined,
            size: 100,
            color: Colors.white,
          ),
          Text(
            "SCT Senior Care",
            style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 30,
                letterSpacing: 2),
          )
        ],
      ),
    );
  }

  Widget _buildBottom() {
    return SizedBox(
      width: mediaSize.width,
      child: Card(
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(30),
              topRight: Radius.circular(30),
            )),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16.0, 24.0, 16.0, 16.0),//all(32.0),
          child: _buildForm(),
        ),
      ),
    );
  }

  Widget _buildForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Welcome",
          style: TextStyle(
              color: myColor, fontSize: 32, fontWeight: FontWeight.w500),
        ),
        _buildGreyText("Please login with your information"),
        const SizedBox(height: 10),
        _buildGreyText("Email address"),
        _buildInputField(emailController),
        const SizedBox(height: 10),
        _buildGreyText("Password"),
        _buildInputField(passwordController, isPassword: true),
        const SizedBox(height: 5),
        _buildRemember(),
        // const SizedBox(height: 5),
        _buildForgot(),
        const SizedBox(height: 5),
        _buildLoginButton(),
        const SizedBox(height: 10),
        _buildOtherLogin(),
      ],
    );
  }

  Widget _buildGreyText(String text) {
    return Text(
      text,
      style: const TextStyle(color: Colors.grey),
    );
  }

  Widget _buildInputField(TextEditingController controller,
      {isPassword = false}) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        suffixIcon: isPassword ? const Icon(Icons.remove_red_eye) : const Icon(Icons.done),
      ),
      obscureText: isPassword,
    );
  }

  Widget _buildRemember() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Checkbox(
                value: rememberUser,
                onChanged: (value) {
                  setState(() {
                    rememberUser = value!;
                  });
                }),
            _buildGreyText("Save ID"),
          ],
        ),
        Row(
            mainAxisAlignment: MainAxisAlignment.end,
          children: [
            _buildGreyText("Auto Login"),
            Switch(
              value: autoLogin,
              activeColor: myColor,
              onChanged: (bool value) {
                setState(() {
                  autoLogin = value;
                });
              },
            ),
          ]
        )
      ],
    );
  }

  Widget _buildForgot() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        TextButton(
            onPressed: () {}, child: _buildGreyText("Forgot Password?"))
      ],
    );
  }

  Widget _buildLoginButton() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        ElevatedButton(
          onPressed: () {
            debugPrint("Email : ${emailController.text}");
            debugPrint("Password : ${passwordController.text}");
          },
          style: ElevatedButton.styleFrom(
            shape: const StadiumBorder(),
            elevation: 20,
            shadowColor: myColor,
            // minimumSize: const Size.fromHeight(40),
          ),
          child: const Text("LOGIN"),
        ),
        ElevatedButton(
          onPressed: () {
            debugPrint("Email : ${emailController.text}");
            debugPrint("Password : ${passwordController.text}");
          },
          style: ElevatedButton.styleFrom(
            shape: const StadiumBorder(),
            elevation: 20,
            shadowColor: myColor,
            // minimumSize: const Size.fromHeight(40),
          ),
          child: const Text("JOIN US"),
        ),
      ],
    );
  }

  Widget _buildOtherLogin() {
    return Center(
      child: Column(
        children: [
          // _buildGreyText("Or Login with"),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Tab(icon: Image.asset("assets/images/facebook.png")),
              Tab(icon: Image.asset("assets/images/twitter.png")),
              Tab(icon: Image.asset("assets/images/github.png")),
            ],
          )
        ],
      ),
    );
  }
}



