import { JSEncrypt } from '../utils/jsencrypt/lib/index'
import UnifiedPreference, { PASSWORD_KEY, UID_KEY } from '../utils/UnifyPreference'

class accountInfoProvider {
  private en = new JSEncrypt();
  private key = [`请自行生成512位的RSA公钥`, `请自行生成512位的RSA私钥`];
  constructor() {
    this.en.setPublicKey(this.key[0]);
    this.en.setPrivateKey(this.key[1]);
  }
  getUID(): string {
    return UnifiedPreference.getSync(UID_KEY);
  }
  encryptPassword(password: string): string {
    const cipher: string | false = this.en.encrypt(password);
    return cipher === false ? '' : cipher;
  }
  getPassword(): string {
    const password: string | false = this.en.decrypt(UnifiedPreference.getSync(PASSWORD_KEY));
    if (password === false) {console.info(`加密解密出现false：${UnifiedPreference.getSync(PASSWORD_KEY)}`)}
    return password === false ? '' : password;
  }
}

export default new accountInfoProvider();