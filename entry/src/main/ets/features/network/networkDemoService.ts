import http from '@ohos.net.http';

export class NetworkDemoService {
  async requestOverHttp(): Promise<string> {
    const request = http.createHttp();
    try {
      const result = await request.request('http://httpbingo.org/get?param=sensitive_data');
      return JSON.stringify(result.result);
    } finally {
      request.destroy();
    }
  }

  async requestOverHttps(): Promise<string> {
    const request = http.createHttp();
    try {
      const result = await request.request('https://httpbingo.org/get?param=sensitive_data', {
        method: http.RequestMethod.GET
      });
      return JSON.stringify(result.result);
    } finally {
      request.destroy();
    }
  }
}
