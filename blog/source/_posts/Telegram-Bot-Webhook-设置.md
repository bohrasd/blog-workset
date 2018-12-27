---
title: Telegram Bot Webhook 设置
date: 2017-10-11 21:15:50
tags:
---

*   自带  
    updater.start\_webhook(listen=’35.200.88.135’, port=443, url\_path=’437433569:AAHJoviAQoiz\_WEmDhnme3Jz6eYR1sSRIik’, key=’/etc/letsencrypt/live/akarat.site/privkey.pem’, cert=’/etc/letsencrypt/live/akarat.site/cert.pem’, webhook\_url=’[https://akarat.site:443/437433569:AAHJoviAQoiz_WEmDhnme3Jz6eYR1sSRIik'](https://akarat.site:443/437433569:AAHJoviAQoiz_WEmDhnme3Jz6eYR1sSRIik'))
    
*   Nginx方法  
    updater.start\_webhook(listen=’127.0.0.1’, port=5000, url\_path=’437433569:AAHJoviAQoiz_WEmDhnme3Jz6eYR1sSRIik’)
    

updater.bot.set\_webhook(webhook\_url=’[https://akarat.site/437433569:AAHJoviAQoiz_WEmDhnme3Jz6eYR1sSRIik'](https://akarat.site/437433569:AAHJoviAQoiz_WEmDhnme3Jz6eYR1sSRIik'), certificate=open(‘/etc/letsencrypt/live/akarat.site/cert.pem’, ‘rb’))

来自 [https://github.com/python-telegram-bot/python-telegram-bot/wiki/Webhooks](https://github.com/python-telegram-bot/python-telegram-bot/wiki/Webhooks)

nginx中设置反向代理

*   初始化  
    from telegram.ext import Updater  
    updater = Updater(token=’437433569:AAHJoviAQoiz_WEmDhnme3Jz6eYR1sSRIik’)
    
*   Webhook 方式  
    import telegram  
    bot = telegram.Bot(token=’437433569:AAHJoviAQoiz_WEmDhnme3Jz6eYR1sSRIik’)  
    bot.set\_webhook(webhook\_url=’[https://akarat.site/437433569:AAHJoviAQoiz_WEmDhnme3Jz6eYR1sSRIik'](https://akarat.site/437433569:AAHJoviAQoiz_WEmDhnme3Jz6eYR1sSRIik'), certificate=open(‘/etc/letsencrypt/live/akarat.site/fullchain.pem’, ‘rb’))
    

