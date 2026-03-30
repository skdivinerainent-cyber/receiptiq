exports.handler = async function(event) {
  if (event.httpMethod !== 'POST') {
    return {
      statusCode: 405,
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ error: 'Method not allowed. Use POST.' })
    };
  }

  const apiKey = process.env.CLAUDE_API_KEY;
  if (!apiKey) {
    return {
      statusCode: 500,
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ error: 'Missing CLAUDE_API_KEY environment variable.' })
    };
  }

  let payload;
  try {
    payload = JSON.parse(event.body || '{}');
  } catch (error) {
    return {
      statusCode: 400,
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ error: 'Invalid request body JSON.' })
    };
  }

  const image = payload?.image;
  if (!image?.data || !image?.media_type) {
    return {
      statusCode: 400,
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ error: 'Request body must include image.data and image.media_type.' })
    };
  }

  const prompt = `You are a receipt and invoice data extraction AI. Analyze this receipt image and extract the following fields.
Respond ONLY with a valid JSON object, no markdown, no explanation.

{
  "merchant": "business name",
  "amount": 0.00,
  "currency_original": "USD",
  "amount_original": 0.00,
  "transaction_date": "YYYY-MM-DD",
  "category": "Travel|Meals|Software|Office|Client Entertainment|Other",
  "tax_status": "deductible|non_deductible|partial",
  "description": "brief description",
  "confidence_merchant": 0.95,
  "confidence_amount": 0.95,
  "confidence_category": 0.85,
  "confidence_tax": 0.80
}

Rules:
- amount should be in USD (convert if needed, use approximate rate)
- transaction_date must be YYYY-MM-DD format
- category must be exactly one of the listed options
- confidence values are 0.0 to 1.0
- If you cannot read a field clearly, use null`;

  const body = {
    model: 'claude-sonnet-4-20250514',
    max_tokens_to_sample: 1000,
    messages: [{
      role: 'user',
      content: [
        {
          type: 'image',
          source: {
            type: 'base64',
            media_type: image.media_type,
            data: image.data
          }
        },
        {
          type: 'text',
          text: prompt
        }
      ]
    }]
  };

  try {
    const response = await fetch('https://api.anthropic.com/v1/messages', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'x-api-key': apiKey,
        'anthropic-version': '2023-06-01'
      },
      body: JSON.stringify(body)
    });

    const result = await response.json();
    if (!response.ok) {
      return {
        statusCode: response.status,
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ error: result?.message || 'Claude API request failed.' })
      };
    }

    const rawText = result?.completion || result?.output?.[0]?.content?.find(item => item.type === 'text')?.text || result?.output?.[0]?.content?.[0]?.text || '';
    const cleanText = rawText.replace(/```json|```/g, '').trim();

    let parsed;
    try {
      parsed = JSON.parse(cleanText);
    } catch (error) {
      return {
        statusCode: 502,
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ error: 'Unable to parse Claude response as JSON.', raw: cleanText })
      };
    }

    return {
      statusCode: 200,
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ data: parsed })
    };
  } catch (error) {
    return {
      statusCode: 500,
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ error: 'Claude extract failed.', details: error.message })
    };
  }
};
