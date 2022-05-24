import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shader/shader.dart';

void main() {
  runApp(const MaterialApp(home: ScreenUsingShader()));
}

class ScreenUsingShader extends StatefulWidget {
  const ScreenUsingShader({Key? key}) : super(key: key);

  @override
  State<ScreenUsingShader> createState() => _ScreenUsingShaderState();
}

class _ScreenUsingShaderState extends State<ScreenUsingShader> {
  ui.Image? img;

  @override
  void initState() {
    super.initState();
    rootBundle.load("assets/images/erdkugel.jpg").then((value) {
      ui.decodeImageFromList(value.buffer.asUint8List(), (result) {
        img = result;
        setState(() {});
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GlslFragmentProgramWebserviceBuilder(
        //shadercWebserviceBaseUrl: "http://localhost:8080",
        code: '''
#version 320 es

precision highp float;

layout (location = 0) out vec4 fragColor;
layout (location = 0) uniform sampler2D tex;

void main() {
  vec2 coords = 0.005*(gl_FragCoord.xy);
  vec4 texColor=texture(tex,coords);
  fragColor = texColor;
}
''',
        builder: (context, shaderProgram) {
          if (shaderProgram == null) {
            return const Center(child: CircularProgressIndicator());
          }
          return RebuildEachFrame(builder: (context) {
            return LayoutBuilder(builder: (context, constraints) {
              if (img != null) {
                return SizedBox.expand(
                  child: CustomPaint(painter: ShaderPainter(shaderProgram, img!)),
                );
              }
              return Container();
            });
          });
        },
      ),
    );
  }
}

/// Will paint an area with our beautiful fragment shader
class ShaderPainter extends CustomPainter {
  final ui.FragmentProgram shaderProgram;
  final ui.Image img;
  ShaderPainter(this.shaderProgram, this.img);

  @override
  void paint(Canvas canvas, Size size) {
    final ImageShader imgS = ImageShader(
        img,
        ui.TileMode.repeated,
        ui.TileMode.repeated,
        Float64List.fromList(
          [
            1, 0, 0, 0, //
            0, 1, 0, 0, //
            0, 0, 1, 0, //
            0, 0, 0, 1, //
          ],
        ));
    final shader = shaderProgram.shader(
      floatUniforms: Float32List.fromList([]),
      samplerUniforms: [imgS],
    );

    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..shader = shader,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
