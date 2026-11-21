# 亚洲PM归因TBL癌经济负担：复现代码

本仓库对应1990—2023年亚洲45国研究，采用已冻结的GBD相关输入与WDI宏观数据。主分析使用 `VSLY=VSL/(HALE/2)`，金额为2023年不变价国际元。

## 使用步骤

1. 下载或克隆仓库，解压授权取得的本地复现数据。
2. 一次性安装R依赖：`Rscript Code/install_packages.R`。
3. 运行完整分析：`Rscript Code/run_all.R --input-dir /本地复现数据/Inputs`。
4. 检验结果：`python3 Code/validate_results.py`。
5. 重绘放大加粗版图件：在第3步命令末尾加 `--publication-figures`，并在输入目录中放入地图档案。

所有结果生成在 `Results/`。可通过 `--output-dir` 指定其他输出位置。脚本不依赖原项目中文目录名，不会自动刷新世界银行数据。R全流程包含分析、模型验证、分解、敏感性分析；Python独立估值脚本只需标准库：

```sh
python3 Code/reproduce_valuation.py --input-dir /本地复现数据/Inputs
```

## 数据和参数

`Code / Data / Sources / Parameters / Documentation` 五类目录与建议结构对应。经济估值输入、GBD疾病负担、HALE与人口子集的结构见 `Data/Inputs/*_schema.csv`。主分析衍生文件包含国家ID、年份、性别、DALYs、HALE、人均GDP、GDP、人口、VSL、VSLY、VLW、VLW/GDP和人均VLW。

- 主分析：4,548条有效估值记录。
- 全输入网格：4,590条，保留42条缺少经济数据的记录。
- 完整敏感性：27,288条，覆盖弹性0.5、1、1.5和HALE、HALE/2共六种组合。
- `VLW_GDP` 为比例，`VLW_GDP_pct` 为百分数，二者不可混用。
- 43国是完整历史固定面板；2023年主结果仍纳入45国。

公开仓库包含WDI冻结快照、全部代码、参数与数据结构。GBD输入、逐行衍生结果及地图档案单独保留在本地复现数据包中，未自动作为可再分发文件加入公开仓库。获取方式及许可范围见 `Documentation/DATA_ACCESS.md`、`Documentation/DATA_USE.md`。

详细字段与复现步骤见 `Documentation/DATA_DICTIONARY.md`、`Documentation/REPRODUCIBILITY.md`。本包不包含投稿手稿、审稿人通信、历史问答或本机绝对路径。
