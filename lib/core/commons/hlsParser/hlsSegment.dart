class HlsEncryptionKey({required final String method, required final String uri, required final String? iv});

class HlsSegment({
  required final String url,
  required final double duration,
  required final int sequenceNumber,
  required final HlsEncryptionKey? encryptionKey,
});