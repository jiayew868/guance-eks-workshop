# demo背景介绍

这是[真实用户体验（rum）](https://docs.guance.com/real-user-monitoring/)的demo，使用最容易上手的[vue](https://cli.vuejs.org/config/)，保证哪怕前端初学者也能够快速接入观测云的rum，在这个基础上也加入了中高阶功能，供探索。

通过demo的搭建，你将能基本了解[rum的接入](https://docs.guance.com/real-user-monitoring/web/app-access/)，[rum的数据体系](https://docs.guance.com/real-user-monitoring/web/app-data-collection/)，rum的[中阶玩法](https://docs.guance.com/real-user-monitoring/web/custom-sdk/)：

- [自定义user](https://docs.guance.com/real-user-monitoring/web/custom-sdk/user-id/)
- [自定义事件](https://docs.guance.com/real-user-monitoring/web/custom-sdk/add-action/)
- [自定义错误](https://docs.guance.com/real-user-monitoring/web/custom-sdk/add-error/)
- [自定义Tag](https://docs.guance.com/real-user-monitoring/web/custom-sdk/add-additional-tag/)


## vue项目搭建
这里提供两种方式，第一种是手把手创建环境和项目，第二种方式是直接使用仓库已经创建好的项目，项目名称为demo文件夹
### 环境准备
1. node环境，
2. [vue 环境](https://cli.vuejs.org/zh/#%E8%B5%B7%E6%AD%A5)，
这里的vue环境搭建使用Vue CLI 服务，Vue CLI 致力于将 Vue 生态中的工具基础标准化。它确保了各种构建工具能够基于智能的默认配置即可平稳衔接，这样可以专注在撰写应用上，而不必花好几天去纠结配置的问题。与此同时，它也为每个工具提供了调整配置的灵活性，无需 eject。有关[如何快速创建一个vue项目](https://cli.vuejs.org/zh/guide/creating-a-project.html)。

运行以下命令来创建一个新项目：
```

vue create rumworkshopdemo

```
具体的内容详见[如何快速创建一个vue项目](https://cli.vuejs.org/zh/guide/creating-a-project.html)，这里我们先使用vue 2来进行创建，等一切ok后，我们就能看到rumworkshopdemo这个项目啦。

## 接入观测云rum
进入到/public的文件夹下，我们看到了公共模板（index.html）,我们将把观测云的rum代码粘贴到head标签内进去。

```
<script>
(function (h, o, u, n, d) {
    h = h[d] = h[d] || {
    q: [],
    onReady: function (c) {
        h.q.push(c)
    }
    }
    d = o.createElement(u)
    d.async = 1
    d.src = n
    n = o.getElementsByTagName(u)[0]
    n.parentNode.insertBefore(d, n)
})(
    window,
    document,
    'script',
    'https://static.guance.com/browser-sdk/v3/dataflux-rum.js',
    'DATAFLUX_RUM'
)
DATAFLUX_RUM.onReady(function () {
    DATAFLUX_RUM.init({
    applicationId: '<>',//这里需要填写应用id
    datakitOrigin: '<DATAKIT ORIGIN>', // 这里需要填写headless的域名，协议（包括：//），域名（或IP地址）[和端口号]
    env: 'production',
    version: '1.0.0',
    service: 'browser',
    sessionSampleRate: 100,
    sessionReplaySampleRate: 100,
    trackInteractions: true,
    traceType: 'ddtrace', // 非必填，默认为ddtrace，目前支持 ddtrace、zipkin、skywalking_v3、jaeger、zipkin_single_header、w3c_traceparent 6种类型
    allowedTracingOrigins: ['https://api.example.com',/https:\/\/.*\.my-api-domain\.com/],  // 非必填，允许注入trace采集器所需header头部的所有请求列表。可以是请求的origin，也可以是是正则
    });
    window.DATAFLUX_RUM && window.DATAFLUX_RUM.startSessionReplayRecording()
});

</script>
```
就这样简单，就完成了rum的接入，然后启动项目，就能看到观测云上报数据了
启动项目

```
npm i
npm run serve
```

> 如果不想创建项目，也可以直接下载demo内的代码，然后直接运行

```
npm i
npm run serve
```

## 注意
需要将配置文件中的两个参数进行修改，
- applicationId: '<demo>',//这里需要填写应用id
- datakitOrigin: '<DATAKIT ORIGIN>', // 这里需要填写headless的域名，协议（包括：//），域名（或IP地址）[和端口号]
    
    
 ## 剩下的就是高级功能了
 
