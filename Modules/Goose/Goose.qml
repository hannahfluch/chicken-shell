import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Shapes
import Quickshell.Wayland
import Quickshell
import qs.Utils
import qs.Services
import qs.Widgets

Variants {
    model: Quickshell.screens

    delegate: PanelWindow {
        
      id: root
      color: "transparent"
      anchors { left: true; right: true; bottom: true; top: true }
      mask: Region {}
      WlrLayershell.exclusionMode: ExclusionMode.Ignore
      WlrLayershell.layer: WlrLayer.Overlay
      WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
      visible: GooseService.render

      /* ------------------- Parameters ------------------- */
      // use point so we keep fractional position
      property var  positionF: Qt.point(width * 0.5, height * 0.75)
      // 0°=right, 90°=down
      property real angleDeg: 40
      property real neckLerp: 0.0

      // Speeds/accel
      property real directionDeg: 90
      property var  velocity: Qt.point(0, 0)
      property var  targetPos: Qt.point(width * 0.25, height * 0.75)
      property real currentSpeed: 80         // Walk = 80, Run = 200, Charge = 400
      property real currentAccel: 1300       // Normal = 1300, Charge = 2300
      property real stepTime: 0.2            // 0.2 (walk/run), 0.1 (charge)

      // Wander task (very light port)
      property real _wanderStart: 0
      property real _wanderDuration: 6
      property real _pauseStart: -1
      property real _pauseDuration: 0

      // Timing
      property real _lastTsMs: Date.now()

      // Feet animation state
      readonly property real wantStepAtDistance: 5          
      readonly property real feetDistanceApart: 6           
      readonly property real stepOvershootPx: 0.4 * 5       
      property var   lFootPos: leftFootHome
      property var   rFootPos: rightFootHome
      property real  lFootMoveStart: -1
      property real  rFootMoveStart: -1
      property var   lFootMoveOrigin: leftFootHome
      property var   rFootMoveOrigin: rightFootHome
      property var   lFootMoveDir: Qt.point(0, 0)
      property var   rFootMoveDir: Qt.point(0, 0)

      property real  liftHeight: 1
      property real  lFootLift: 0
      property real  rFootLift: 0

      // Helpers (tiny vector ops)
      function v(x, y){ return Qt.point(x, y) }
      function add(a,b){ return v(a.x+b.x, a.y+b.y) }
      function sub(a,b){ return v(a.x-b.x, a.y-b.y) }
      function mul(a,k){ return v(a.x*k, a.y*k) }
      function mag(v){ return Math.hypot(v.x, v.y) }
      function norm(vp){ let m=mag(vp); return m>1e-6 ? v(vp.x/m, vp.y/m) : v(0,0) }
      function lerp(a,b,t){ return a+(b-a)*t }
      function clamp(x,a,b){ return Math.max(a, Math.min(b,x)) }
      function angleToVec(deg){ let r=deg*Math.PI/180; return v(Math.cos(r), Math.sin(r)) }
      function vecToAngle(v){ return Math.atan2(v.y, v.x)*180/Math.PI }
      function cubicInOut(t){ return (t<0.5) ? 4*t*t*t : 1 - Math.pow(-2*t+2,3)/2 }

      readonly property real _rad: angleDeg * Math.PI / 180
      readonly property real _fx:  Math.cos(_rad)
      readonly property real _fy:  Math.sin(_rad)
      readonly property real _lx: -Math.sin(_rad)
      readonly property real _ly:  Math.cos(_rad)
      readonly property real _ux: 0
      readonly property real _uy: -1

      /* ------------------- Integer base ------------------- */
      readonly property int _ix: Math.floor(positionF.x)
      readonly property int _iy: Math.floor(positionF.y)

      /* ------------------- Shadow ------------------- */
      property real shadowRadiusX: 20
      property real shadowRadiusY: 15

      /* ------------------- Feet (float centers) ------------------- */
      property real footRadius: 4
      readonly property var leftFootHome:  Qt.point(_ix, _iy)
      readonly property var rightFootHome: Qt.point(
        _ix + _lx * feetDistanceApart,
        _iy + _ly * feetDistanceApart
      )

      /* ------------------- Rig ------------------- */
      readonly property var underbodyCenter: Qt.point(_ix + _ux * 9,  _iy + _uy * 9)
      readonly property var bodyCenter:      Qt.point(_ix + _ux * 14, _iy + _uy * 14)

      readonly property real _neckUp:      20 * (1 - neckLerp) + 10 * neckLerp
      readonly property real _neckForward:  3 * (1 - neckLerp) + 16 * neckLerp

      readonly property var neckBase: Qt.point(
        bodyCenter.x + _fx * 15,
        bodyCenter.y + _fy * 15
      )
      readonly property var neckHeadPoint: Qt.point(
        neckBase.x + _fx * _neckForward + _ux * _neckUp,
        neckBase.y + _fy * _neckForward + _uy * _neckUp
      )
      readonly property var head1End: Qt.point(
        neckHeadPoint.x + _fx * 3 - _ux * 1,
        neckHeadPoint.y + _fy * 3 - _uy * 1
      )
      readonly property var head2End: Qt.point(
        head1End.x + _fx * 5,
        head1End.y + _fy * 5
      )
      readonly property var beakTip: Qt.point(
        head2End.x + _fx * 5,
        head2End.y + _fy * 5
      )

      /* ------------------- Eyes ------------------- */
      readonly property real _bx: 1.3
      readonly property real _by: 0.4
      readonly property real _slx: _lx * _bx
      readonly property real _sly: _ly * _by
      readonly property real _eyeBaseX: neckHeadPoint.x + _ux * 3 + _fx * 5
      readonly property real _eyeBaseY: neckHeadPoint.y + _uy * 3 + _fy * 5
      readonly property real eyeOffset: 5
      readonly property real eyeRadius: 2
      readonly property real leftEyeX:  _eyeBaseX - _slx * eyeOffset
      readonly property real leftEyeY:  _eyeBaseY - _sly * eyeOffset
      readonly property real rightEyeX: _eyeBaseX + _slx * eyeOffset
      readonly property real rightEyeY: _eyeBaseY + _sly * eyeOffset

      function setSpeed(tier) {
        // "Walk", "Run", "Charge"
        if (tier === "Walk")  { currentSpeed = 80;  currentAccel = 1300; stepTime = 0.2 }
        if (tier === "Run")   { currentSpeed = 200; currentAccel = 1300; stepTime = 0.2 }
        if (tier === "Charge"){ currentSpeed = 400; currentAccel = 2300; stepTime = 0.1 }
      }

      function startWander() {
        setSpeed("Walk")
        _wanderStart = nowSec()

        _wanderDuration = randRange(4, 9)
        _pauseStart = -1
        _pauseDuration = 0

        // initial wander target
        retargetWithinSeconds(randRange(1, 6))
      }

      function nowSec(){ return Date.now()/1000 }
      function randRange(a,b){ return a + Math.random()*(b-a) }

      function retargetWithinSeconds(maxWalkTime) {
        let rnd = v(Math.random()*width, Math.random()*height)
        let toRnd = sub(rnd, positionF)
        let dist = mag(toRnd)
        let maxDist = currentSpeed * maxWalkTime
        if (dist > maxDist) rnd = add(positionF, mul(norm(toRnd), maxDist))
        targetPos = rnd
      }

      function runWander() {
        // End wander and restart periodically
        if (nowSec() - _wanderStart > _wanderDuration) {
          startWander()
          return
        }
        // execute pause
        if (_pauseStart > 0) {
          if (nowSec() - _pauseStart > _pauseDuration) {
            _pauseStart = -1
            retargetWithinSeconds(randRange(1,6))
          } else {
            velocity = v(0,0)
          }
          return
        }
        // pause a bit when close to target
        if (mag(sub(positionF, targetPos)) < 20) {
          _pauseStart = nowSec()
          _pauseDuration = randRange(1, 2) // 1..2s
        }
      }

        function solveFeet() {
          const lfHome = leftFootHome
          const rfHome = rightFootHome

          if (lFootMoveStart < 0 && rFootMoveStart < 0) {
            // choose which foot to move (only when both are planted)
            if (mag(sub(lFootPos, lfHome)) > wantStepAtDistance) {
              lFootMoveOrigin = lFootPos
              lFootMoveDir    = norm(sub(lfHome, lFootPos))
              lFootMoveStart  = nowSec()
              return
            }
            if (mag(sub(rFootPos, rfHome)) > wantStepAtDistance) {
              rFootMoveOrigin = rFootPos
              rFootMoveDir    = norm(sub(rfHome, rFootPos))
              rFootMoveStart  = nowSec()
              return
            }
            return
          }

          if (lFootMoveStart > 0) {
            const b = add(lfHome, mul(lFootMoveDir, stepOvershootPx)) 
            const t = clamp((nowSec() - lFootMoveStart) / stepTime, 0, 1)
            const p = cubicInOut(t)
            lFootPos = v( lerp(lFootMoveOrigin.x, b.x, p), lerp(lFootMoveOrigin.y, b.y, p) )
            if (t >= 1) {
              lFootPos = b
              lFootMoveStart = -1
            }
            return
          }

          if (rFootMoveStart > 0) {
            const b2 = add(rfHome, mul(rFootMoveDir, stepOvershootPx))
            const t2 = clamp((nowSec() - rFootMoveStart) / stepTime, 0, 1)
            const p2 = cubicInOut(t2)
            rFootPos = v( lerp(rFootMoveOrigin.x, b2.x, p2), lerp(rFootMoveOrigin.y, b2.y, p2) )
            if (t2 >= 1) {
              rFootPos = b2
              rFootMoveStart = -1
            }
          }
        }

      function tickOnce() {
        // console.log("Goose position:", positionF.x, positionF.y)
        // dt
        const nowMs = Date.now()
        const dt = Math.max(0.001, (nowMs - _lastTsMs) / 1000.0)   // seconds
        _lastTsMs = nowMs

        if (dt > 0.25) {
            Logger.log("Goose", "Large dt detected");
            dt = 0.016
        }
        if (!positionF || !velocity || !targetPos) {
              Logger.log("Goose", "State invalid, resetting")
              positionF = Qt.point(width * 0.5, height * 0.75)
              velocity = Qt.point(0, 0)
              targetPos = Qt.point(width * 0.25, height * 0.75)
              return
        }

        runWander()

        // steer
        const targetDir = norm(sub(targetPos, positionF))
        const blended = norm(add(mul(angleToVec(directionDeg), 1-0.25), mul(targetDir, 0.25)))
        directionDeg = vecToAngle(blended)
    
        // accelarate torwards targed
        if (mag(velocity) > currentSpeed) velocity = mul(norm(velocity), currentSpeed)
        velocity = add(velocity, mul(targetDir, currentAccel * dt))

        positionF = add(positionF, mul(velocity, dt))
        angleDeg = directionDeg

        solveFeet()

        // Neck extension when moving fast
        const extend = (currentSpeed >= 200) ? 1 : 0
        neckLerp = lerp(neckLerp, extend, 0.075)
      }

      Timer {
        id: ticker
        interval: 16
        repeat: true
        running: GooseService.render
        triggeredOnStart: true
        onTriggered: tickOnce()
      }

      Component.onDestruction: console.log("Goose destroyed for screen", screen.name)
      Component.onCompleted: {
        lFootPos = leftFootHome
        rFootPos = rightFootHome
        // Spawn with a wander task
        startWander()
      }

      /* =================== DRAWING =================== */

      // Shadow (float center is fine)
      Shape {
        anchors.fill: parent
        ShapePath {
          fillColor: Color.shadow; strokeWidth: 0
          PathSvg {
            path: "M " + (_ix - shadowRadiusX) + " " + _iy +
                  " a " + shadowRadiusX + " " + shadowRadiusY + " 0 1 0 " + (2*shadowRadiusX) + " 0" +
                  " a " + shadowRadiusX + " " + shadowRadiusY + " 0 1 0 " + (-2*shadowRadiusX) + " 0 Z"
          }
        }
      }

      /* Feet (float centers) */
      Shape {
        anchors.fill: parent
        ShapePath {
          fillColor: Color.foot; strokeWidth: 0
          PathSvg {
            path: "M " + (lFootPos.x - footRadius) + " " + lFootPos.y +
                  " a " + footRadius + " " + footRadius + " 0 1 0 " + (2*footRadius) + " 0" +
                  " a " + footRadius + " " + footRadius + " 0 1 0 " + (-2*footRadius) + " 0 Z"
          }
        }
      }
      Shape {
        anchors.fill: parent
        ShapePath {
          fillColor: Color.foot; strokeWidth: 0
          PathSvg {
            path: "M " + (rFootPos.x - footRadius) + " " + rFootPos.y +
                  " a " + footRadius + " " + footRadius + " 0 1 0 " + (2*footRadius) + " 0" +
                  " a " + footRadius + " " + footRadius + " 0 1 0 " + (-2*footRadius) + " 0 Z"
          }
        }
      }

      /* ---- Underlayer (LightGray) ---- */
      Shape {
        anchors.fill: parent
        ShapePath {
          strokeColor: Color.under; strokeWidth: 24; fillColor: "transparent"
          capStyle: ShapePath.RoundCap; joinStyle: ShapePath.RoundJoin
          PathSvg { path:
            "M " + Math.floor(bodyCenter.x + _fx*11) + " " + Math.floor(bodyCenter.y + _fy*11) +
            " L " + Math.floor(bodyCenter.x - _fx*11) + " " + Math.floor(bodyCenter.y - _fy*11)
          }
        }
      }
      Shape {
        anchors.fill: parent
        ShapePath {
          strokeColor: Color.under; strokeWidth: 15; fillColor: "transparent"
          capStyle: ShapePath.RoundCap
          PathSvg { path:
            "M " + Math.floor(neckBase.x) + " " + Math.floor(neckBase.y) +
            " L " + Math.floor(neckHeadPoint.x) + " " + Math.floor(neckHeadPoint.y)
          }
        }
      }
      Shape {
        anchors.fill: parent
        ShapePath {
          strokeColor: Color.under; strokeWidth: 17; fillColor: "transparent"
          capStyle: ShapePath.RoundCap
          PathSvg { path:
            "M " + Math.floor(neckHeadPoint.x) + " " + Math.floor(neckHeadPoint.y) +
            " L " + Math.floor(head1End.x) + " " + Math.floor(head1End.y)
          }
        }
      }
      Shape {
        anchors.fill: parent
        ShapePath {
          strokeColor: Color.under; strokeWidth: 12; fillColor: "transparent"
          capStyle: ShapePath.RoundCap
          PathSvg { path:
            "M " + Math.floor(head1End.x) + " " + Math.floor(head1End.y) +
            " L " + Math.floor(head2End.x) + " " + Math.floor(head2End.y)
          }
        }
      }
      Shape {
        anchors.fill: parent
        ShapePath {
          strokeColor: Color.under; strokeWidth: 15; fillColor: "transparent"
          capStyle: ShapePath.RoundCap
          PathSvg { path:
            "M " + Math.floor(underbodyCenter.x + _fx*7) + " " + Math.floor(underbodyCenter.y + _fy*7) +
            " L " + Math.floor(underbodyCenter.x - _fx*7) + " " + Math.floor(underbodyCenter.y - _fy*7)
          }
        }
      }

      /* ---- Main (White) ---- */
      Shape {
        anchors.fill: parent
        ShapePath {
          strokeColor: Color.body; strokeWidth: 22; fillColor: "transparent"
          capStyle: ShapePath.RoundCap
          PathSvg { path:
            "M " + Math.floor(bodyCenter.x + _fx*11) + " " + Math.floor(bodyCenter.y + _fy*11) +
            " L " + Math.floor(bodyCenter.x - _fx*11) + " " + Math.floor(bodyCenter.y - _fy*11)
          }
        }
      }
      Shape {
        anchors.fill: parent
        ShapePath {
          strokeColor: Color.body; strokeWidth: 13; fillColor: "transparent"
          capStyle: ShapePath.RoundCap
          PathSvg { path:
            "M " + Math.floor(neckBase.x) + " " + Math.floor(neckBase.y) +
            " L " + Math.floor(neckHeadPoint.x) + " " + Math.floor(neckHeadPoint.y)
          }
        }
      }
      Shape {
        anchors.fill: parent
        ShapePath {
          strokeColor: Color.body; strokeWidth: 15; fillColor: "transparent"
          capStyle: ShapePath.RoundCap
          PathSvg { path:
            "M " + Math.floor(neckHeadPoint.x) + " " + Math.floor(neckHeadPoint.y) +
            " L " + Math.floor(head1End.x) + " " + Math.floor(head1End.y)
          }
        }
      }
      Shape {
        anchors.fill: parent
        ShapePath {
          strokeColor: Color.body; strokeWidth: 10; fillColor: "transparent"
          capStyle: ShapePath.RoundCap
          PathSvg { path:
            "M " + Math.floor(head1End.x) + " " + Math.floor(head1End.y) +
            " L " + Math.floor(head2End.x) + " " + Math.floor(head2End.y)
          }
        }
      }

      /* ---- Beak ---- */
      Shape {
        anchors.fill: parent
        ShapePath {
          strokeColor: Color.beak; strokeWidth: 9; fillColor: "transparent"
          capStyle: ShapePath.RoundCap
          PathSvg { path:
            "M " + Math.floor(head2End.x) + " " + Math.floor(head2End.y) +
            " L " + Math.floor(beakTip.x) + " " + Math.floor(beakTip.y)
          }
        }
      }

      /* ---- Eyes (float centers, r=2) ---- */
      Shape {
        anchors.fill: parent
        ShapePath {
          fillColor: Color.eye; strokeWidth: 0
          PathSvg {
            path: "M " + (leftEyeX - eyeRadius) + " " + leftEyeY +
                  " a " + eyeRadius + " " + eyeRadius + " 0 1 0 " + (2*eyeRadius) + " 0" +
                  " a " + eyeRadius + " " + eyeRadius + " 0 1 0 " + (-2*eyeRadius) + " 0 Z"
          }
        }
      }
      Shape {
        anchors.fill: parent
        ShapePath {
          fillColor: Color.eye; strokeWidth: 0
          PathSvg {
            path: "M " + (rightEyeX - eyeRadius) + " " + rightEyeY +
                  " a " + eyeRadius + " " + eyeRadius + " 0 1 0 " + (2*eyeRadius) + " 0" +
                  " a " + eyeRadius + " " + eyeRadius + " 0 1 0 " + (-2*eyeRadius) + " 0 Z"
          }
        }
      }
    }
}
