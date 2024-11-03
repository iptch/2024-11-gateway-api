curl -k -H "conversation-time: hello" https://nginx-header.apps.example.com:8443
curl -k -H "conversation-time: bye" https://nginx-header.apps.example.com:8443
and default:
curl -k -H https://nginx-header.apps.example.com:8443