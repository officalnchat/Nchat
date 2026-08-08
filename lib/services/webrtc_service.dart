import 'package:flutter_webrtc/flutter_webrtc.dart';

class WebRTCService {
  RTCPeerConnection? peerConnection;

  MediaStream? remoteStream;

  MediaStream? localStream;

  final Map<String, dynamic> configuration = {
    "iceServers": [
      {
        "urls": [
          "stun:stun.l.google.com:19302",
        ],
      },
    ],
  };

  // ===========================
  // Initialize
  // ===========================

  Future<void> initialize() async {
    peerConnection =
        await createPeerConnection(
      configuration,
    );

    localStream =
        await navigator.mediaDevices.getUserMedia(
      {
        "audio": true,
        "video": false,
      },
    );

    await Helper.setSpeakerphoneOn(true);


    for (final track
        in localStream!.getTracks()) {
      peerConnection!.addTrack(
        track,
        localStream!,
      );
    }
    final audioTracks =
    localStream!.getAudioTracks();

if (audioTracks.isNotEmpty) {

  audioTracks.first.enabled = true;

  print("🎤 Local Audio Enabled");

}
  }

  // ===========================
  // Create Offer
  // ===========================

  Future<RTCSessionDescription>
      createOffer() async {

    final offer =
        await peerConnection!
            .createOffer();

    await peerConnection!
        .setLocalDescription(
      offer,
    );

    return offer;
  }

  // ===========================
  // Create Answer
  // ===========================

  Future<RTCSessionDescription>
      createAnswer() async {

    final answer =
        await peerConnection!
            .createAnswer();

    await peerConnection!
        .setLocalDescription(
      answer,
    );

    return answer;
  }
    // ===========================
  // Set Remote Description
  // ===========================

  Future<void> setRemoteDescription(
  RTCSessionDescription description,
) async {

  if (peerConnection == null) {
    print("⚠️ PeerConnection is null");
    return;
  }

  final state = peerConnection!.signalingState;

  if (state ==
      RTCSignalingState.RTCSignalingStateClosed) {
    print("⚠️ PeerConnection already closed");
    return;
  }

  try {
    await peerConnection!
        .setRemoteDescription(description);

    print("✅ Remote Description Set");

  } catch (e) {
    print("❌ setRemoteDescription Error: $e");
  }
}

  // ===========================
  // Add ICE Candidate
  // ===========================

  Future<void> addIceCandidate(
    RTCIceCandidate candidate,
  ) async {
    await peerConnection!
        .addCandidate(
      candidate,
    );
  }

  // ===========================
  // ICE Candidate Callback
  // ===========================

  void onIceCandidate(
    Function(RTCIceCandidate candidate)
        callback,
  ) {
    peerConnection!.onIceCandidate =
        (candidate) {
      if (candidate != null) {
        callback(candidate);
      }
    };
  }

  // ===========================
  // Remote Audio Callback
  // ===========================

  void onTrack(
  Function(MediaStream stream) callback,
) {
 peerConnection!.onTrack = (event) {

  print("🎵 Track Kind : ${event.track.kind}");

  if (event.streams.isNotEmpty) {

    remoteStream = event.streams.first;

    print("🎤 Remote Stream Received");

    callback(remoteStream!);

  }

};
}

  // ===========================
  // Dispose
  // ===========================

  Future<void> dispose() async {

  localStream?.getTracks().forEach((track) {
    track.stop();
  });

  remoteStream?.getTracks().forEach((track) {
    track.stop();
  });

  await peerConnection?.close();

  await localStream?.dispose();

  await remoteStream?.dispose();

  peerConnection = null;
  localStream = null;
  remoteStream = null;

  print("🧹 WebRTC Disposed");
}
}