V2.0

设计上摆脱之前一个脚本全干的思路，单个natter服务对应单个脚本，多端口需要多个natter服务。\
此次实现了动态式的跳转，能保留跳转后的路径和query字符串。

具体使用方式看几遍代码应该就能看懂了

# 以下是代码喂给deepseek后给出的使用文档，作者不保证真实性，仅供参考。
____
<details type="reasoning" done="true" duration="7">
<summary>Thought for 7 seconds</summary>
> 我们有一个shell脚本，它使用Natter V2协议，并利用Cloudflare API来更新动态重定向规则。脚本的目的是根据Natter给的外部IP和端口，更新Cloudflare上已有的重定向规则（规则名为test8089），使其目标URL中的端口更新为当前的公网端口。
> 
> 文档需要包含：
> 1. 脚本功能说明
> 2. 环境变量配置说明
> 3. 使用步骤
> 4. 注意事项
> 
> 注意：脚本中使用了jq, sed, curl，因此需要确保这些工具已安装。
> 
> 下面开始编写使用文档：
</details>

### Cloudflare 动态端口重定向脚本使用文档

#### 🛠️ 功能说明
此脚本用于自动化更新 Cloudflare 规则集中动态重定向规则的**目标端口**。当使用 Natter V2 协议获得新的公网 IP 和端口时，脚本会将规则 `test8089` 的目标 URL 中的端口替换为当前获得的公网端口（如将 `b.test.com:OLD_PORT` 更新为 `b.test.com:NEW_PORT`）

#### 🔧 依赖工具
```bash
# 必须提前安装
sudo apt-get install jq sed curl  # Debian/Ubuntu
sudo yum install jq sed curl     # CentOS
```

#### ⚙️ 环境变量配置
编辑脚本文件顶部变量（**必须填写**）：
```bash
CLOUDFLARE_ZONE_ID='你的区域ID'           # Cloudflare 区域ID
CLOUDFLARE_AUTH_KEY='Bearer令牌'         # API 认证密钥
CLOUDFLARE_API_KEY='全局API密钥'         # 账户API密钥
CLOUDFLARE_EMAIL='你的账号邮箱'            # Cloudflare 注册邮箱

# 可选自定义项（如需更改规则名/URL）
CLOUDFLARE_RULE_NAME='test8089'          # 要修改的规则名
CLOUDFLARE_RULE_FORM_URL='http://a.test.com'  # 原始URL
CLOUDFLARE_RULE_TARGET_URL='http://b.test.com/' # 目标URL基础
```

#### 🚀 使用方法
1. **赋予执行权限**
   ```bash
   chmod +x script_name.sh
   ```
2. **通过 Natter 自动触发（推荐）**  
   在 Natter 的配置中直接调用脚本（参数由 Natter V2 协议提供）：
   ```bash
   ./script_name.sh "$1" "$2" "$3" "$4" "$5"
   ```
   参数说明：  
   `$4` = 公网IP (自动捕获)  
   `$5` = 公网端口 (自动捕获)

3. **手动执行（测试用）**
   ```bash
   ./script_name.sh protocol private_ip private_port NEW_PUBLIC_IP NEW_PORT
   # 示例： ./script_name.sh tcp 192.168.1.100 80 203.0.113.5 51820
   ```

#### 🔄 工作流程
1. 从 Natter 获取公网 IP 和端口
2. 查询 Cloudflare 现有规则集 (`test8089`)
3. 将目标URL中的 `NEW_PORT` 替换为实际端口（如 `http://b.test.com:51820/$1`）
4. 通过 Cloudflare API 更新规则集

#### ⚠️ 注意事项
1. **规则预处理**  
   - 确保已在 Cloudflare 创建名为 **`test8089`** 的重定向规则
   - 目标 URL 格式必须为：`http://b.test.com:NEW_PORT/${1}`（脚本自动替换 `NEW_PORT`）

2. **权限要求**  
   API 令牌需包含以下权限：
   ```
   Zone.Rulesets: [Read, Edit]
   Zone.Page Rules: [Read, Edit]
   ```

3. **错误排查**  
   - 调试文件：脚本生成的 `1.json` 包含提交前的规则内容
   - 关键命令检查：
     ```bash
     # 验证工具安装
     which jq && which sed && which curl 
     # 测试API连接
     curl -GET -H "Authorization: Bearer $CLOUDFLARE_AUTH_KEY" \
     "https://api.cloudflare.com/client/v4/zones/$CLOUDFLARE_ZONE_ID/rulesets"
     ```

4. **URL规范**  
   - 使用完整的 URL（包含 `http://`）
   - 尾部斜杠处理：  
     目标URL会统一去除结尾 `/`（`b.test.com/` → `b.test.com`）

#### ✅ 预期效果
当访问：
```
http://a.test.com/path?query=123
```
将被重定向至：
```
http://b.test.com:NEW_PORT/path?query=123
```
（其中 `NEW_PORT` 为 Natter 获取的最新端口）

> 💡 建议搭配 crontab 或 systemd 服务定期检查端口变更
