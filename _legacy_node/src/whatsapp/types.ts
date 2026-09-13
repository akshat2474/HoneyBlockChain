export interface WebhookPayload {
  object: string;
  entry: WebhookEntry[];
}

export interface WebhookEntry {
  id: string;
  changes: Change[];
}

export interface Change {
  value: Value;
  field: string;
}

export interface Value {
  messaging_product: string;
  metadata: {
    display_phone_number: string;
    phone_number_id: string;
  };
  contacts?: Contact[];
  messages?: Message[];
}

export interface Contact {
  profile: {
    name: string;
  };
  wa_id: string;
}

export interface Message {
  from: string;
  id: string;
  timestamp: string;
  type: string;
  text?: {
    body: string;
  };
  image?: {
    mime_type: string;
    sha256: string;
    id: string;
  };
  interactive?: {
    type: string;
    list_reply?: {
      id: string;
      title: string;
      description?: string;
    };
    button_reply?: {
      id: string;
      title: string;
    };
  };
}
