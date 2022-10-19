# flink-table-store-101 [![Awesome](https://cdn.rawgit.com/sindresorhus/awesome/d7305f38d29fed78fa85652e3a63e154dd8e8829/media/badge.svg)](https://github.com/sindresorhus/awesome) [![Docker](https://badgen.net/badge/icon/docker?icon=docker&label)](https://https://docker.com/) [![License](https://img.shields.io/badge/License-Apache_2.0-blue.svg)](https://opensource.org/licenses/Apache-2.0)

这是一个围绕 [Flink Table Store](https://github.com/apache/flink-table-store) (*以下简称* **FTS**) 用例和特性展示的项目集合。

*其它语言版本* [English](https://github.com/LadyForest/flink-table-store-101#readme)

## 用例展示
<table>
    <thead>
        <tr>
            <th>用例</th>
            <th>涉及技术栈</th>
            <th>描述</th>
        </tr>
    </thead>
    <tbody>
        <tr>
          <td><b><code><a href="https://github.com/LadyForest/flink-table-store-101/blob/master/real-time-update/README.zh.md">全增量一体 CDC 实时入湖</a></code></b></td>
            <td rowspan=1>MySQL, Flink, Flink CDC</td>
            <td rowspan=2>基于 <a href="https://www.tpc.org/tpch/">TPC-H 数据集</a>构建的实时 ETL 链路</td>
        </tr>
        <tr>
          <td><b><code><a href="https://github.com/LadyForest/flink-table-store-101/tree/master/lookup-join/README.zh.md">基于 FTS 的维表连接及预聚合</a></code></b></td>
          <td>MySQL, Flink, Flink CDC, Zeppelin</td>
        </tr>
    </tbody>
</table>

## 环境要求
- [Docker and Docker Compose](https://docs.docker.com/)

## 注意
请不要同时运行多个用例，可能存在端口冲突