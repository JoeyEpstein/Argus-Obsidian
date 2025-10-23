"""
B9-Phish to Microsoft Sentinel Connector
Ingests phishing detection events into Log Analytics
"""

import os
import json
import logging
import hashlib
import hmac
import base64
from datetime import datetime
import requests
from typing import Dict, List, Any

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

class B9PhishConnector:
    """Connector for B9-Phish to Sentinel integration"""
    
    def __init__(self):
        self.workspace_id = os.environ.get('WORKSPACE_ID')
        self.shared_key = os.environ.get('SHARED_KEY')
        self.log_type = 'B9Phish_Email_Detections'
        self.api_version = '2016-04-01'
        
    def build_signature(self, date: str, content_length: int, 
                        method: str, content_type: str, resource: str) -> str:
        """Build the authorization signature for Log Analytics API"""
        x_headers = f'x-ms-date:{date}'
        string_to_hash = f"{method}\n{content_length}\n{content_type}\n{x_headers}\n{resource}"
        bytes_to_hash = bytes(string_to_hash, encoding="utf-8")
        decoded_key = base64.b64decode(self.shared_key)
        encoded_hash = base64.b64encode(
            hmac.new(decoded_key, bytes_to_hash, digestmod=hashlib.sha256).digest()
        ).decode()
        return f"SharedKey {self.workspace_id}:{encoded_hash}"
    
    def send_to_sentinel(self, events: List[Dict[str, Any]]) -> bool:
        """Send detection events to Sentinel"""
        body = json.dumps(events)
        method = 'POST'
        content_type = 'application/json'
        resource = '/api/logs'
        rfc1123date = datetime.utcnow().strftime('%a, %d %b %Y %H:%M:%S GMT')
        content_length = len(body)
        
        signature = self.build_signature(
            rfc1123date, content_length, method, content_type, resource
        )
        
        uri = f"https://{self.workspace_id}.ods.opinsights.azure.com{resource}?api-version={self.api_version}"
        
        headers = {
            'content-type': content_type,
            'Authorization': signature,
            'Log-Type': self.log_type,
            'x-ms-date': rfc1123date
        }
        
        response = requests.post(uri, data=body, headers=headers)
        
        if response.status_code >= 200 and response.status_code <= 299:
            logger.info(f"Successfully sent {len(events)} events to Sentinel")
            return True
        else:
            logger.error(f"Failed to send events. Status: {response.status_code}")
            return False

# Usage example
if __name__ == "__main__":
    connector = B9PhishConnector()
    
    # Sample phishing detection event
    sample_event = {
        "TimeGenerated": datetime.utcnow().isoformat(),
        "SenderEmail": "phisher@malicious.com",
        "RecipientEmail": "user@company.com",
        "Subject": "Urgent: Verify your account",
        "DetectionType": "credential_harvesting",
        "DetectionConfidence": 0.92,
        "SPF_Result": "fail",
        "DMARC_Result": "fail",
        "MaliciousURLs": "http://bit.ly/fake-login",
        "AttachmentHash": None
    }
    
    connector.send_to_sentinel([sample_event])
