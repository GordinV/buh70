'use strict';

const DocContext = require('../../doc-context');

const PropTypes = require('prop-types');
const fetchData = require('./../../../libs/fetchData');
const POST_LOAD_LIBS_URL =  require('./../../../config/constants').LIBS.POST_LOAD_LIBS_URL;


const React = require('react'),
    styles = require('./select-data-styles'),
    DataGrid = require('../../components/data-grid/data-grid.jsx'),
    Button = require('../../components/button-register/button-register.jsx'),
    InputText = require('../../components/input-text/input-text.jsx'),
    ModalPage = require('./../../components/modalpage/modalPage.jsx');

class SelectData extends React.PureComponent {
    constructor(props) {
        super(props);
        this.state = {
            value: props.value, /* возвращаемое значение, например id*/
            fieldValue: props.defaultValue, /*видимое значение, например kood или name по указанному в collId */
            readOnly: props.readOnly,
            disabled: props.disabled,
            edited: props.edited,
            gridData: [],
            gridConfig: props.config,
            gridActiveRow: 0,
            show: this.props.show,
            limit: '10'
        };
        this.handleInputChange = this.handleInputChange.bind(this);
        this.handleGridClick = this.handleGridClick.bind(this);
        this.modalPageClick = this.modalPageClick.bind(this);
        this.loadLibs = this.loadLibs.bind(this);
        this.handleClick = this.handleClick.bind(this);
        this.handleGridBtnClick = this.handleGridBtnClick.bind(this);
    }

    componentDidMount() {
        if (this.state.value) {
            this.loadLibs('');
        }
    }

    componentDidUpdate(prevProps, prevState) {
        if (this.state.value && prevState.value !== this.state.value && !this.state.fieldValue) {
            this.loadLibs()
        }
    }

    // will update state if props changed
    static getDerivedStateFromProps(nextProps, prevState) {
        if (nextProps.value !== prevState.value) {
            return {value: nextProps.value};
        } else return null;
    }

    render() {
        let isEditeMode = !this.state.readOnly,
            btnStyle = Object.assign({}, styles.button, {display: isEditeMode ? 'inline' : 'none'});

        let isReadOnly = this.props.readOnly;
        if (this.state.show) {
            isReadOnly = false
        }

        return (
            <div style={styles.wrapper}>
                <InputText ref="inputName"
                           title={this.props.title}
                           name={this.props.name}
                           value={this.state.fieldValue || ''}
                           readOnly={isReadOnly}
                           onChange={this.handleInputChange}/>

                <Button value='v'
                        ref="btnShow"
                        style={btnStyle}
                        onClick={this.handleClick}>
                </Button>
                {
                    this.state.show ? this.modalPage() : null
                }
            </div>
        )
    }

    handleClick() {
        this.setState({
            show: true
        });
    }

    modalPage() {
        let modalObjects = ['btnOk', 'btnCancel'];
        let limitInputStyle = styles.limitInput;

        const toolbarParams = {
            btnAdd: {
                show: true,
                disabled: false
            },
            btnEdit: {
                show: true,
                disabled: false
            },
            btnDelete: {
                show: false,
                disabled: false
            },
            btnPrint: {
                show: false,
                disabled: false
            }
        };
        return (
            <ModalPage
                modalObjects={modalObjects}
                ref="modalpage-grid"
                show={true}
                modalPageBtnClick={this.modalPageClick}
                modalPageName='Vali rea'>
                <div ref="grid-row-container">
                    <InputText ref="input-filter"
                               title='Otsingu parametrid:'
                               name='gridFilter'
                               value={this.state.fieldValue || ''}
                               readOnly={this.props.readOnly || !this.state.show}
                               onChange={this.handleInputChange}/>
                    <DataGrid gridData={this.state.gridData}
                              gridColumns={this.state.gridConfig}
                              onClick={this.handleGridClick}
                              handleGridBtnClick={this.handleGridBtnClick}
                              showToolBar={true}
                              toolbarParams={toolbarParams}
                              ref="data-grid"/>
                    <InputText ref="input-limit"
                               title='Limiit:'
                               width={limitInputStyle}
                               name='limit'
                               value={this.state.limit || '10'}
                               readOnly={false}
                               onChange={this.handleInputChange}/>
                </div>
            </ModalPage>);
    }

    // обработчик события измения значения в текстовом (поисковом) поле
    handleInputChange(name, value) {
        if (this.props.readOnly) {
                console.error ('readonly ');
            return
        }

        if (name === 'gridFilter') {
            // обновим стейт
            this.setState({value: 0, fieldValue: value, show: true}, () => {
                if (value.length) {
                    //выполним запрос
                    setTimeout(() => {
                        this.loadLibs(value);
                    }, 100);
                }

            });
        }

        else {

            this.setState({value: 0, fieldValue: value, show: false}, () => {
                if (value.length) {
                    //выполним запрос
                    setTimeout(() => {
                        this.loadLibs(value);
                    }, 500);
                }

            });

        }


        if (name === 'limit') {
            this.setState({limit: value});
        }
    }

    modalPageClick(event) {
        if (event === 'Ok') {
            // надо найти активную строку

            let boundField = this.props.boundToGrid ? this.props.boundToGrid : 'name', //grid filed name
                boundToData = this.props.boundToData ? this.props.boundToData : false, //InputDefaultValue
                boundFieldData = this.props.name; //inputName = fieldname

            let activeRow = this.state.gridActiveRow,
                value = this.state.gridData[activeRow]['id'],
                fieldValue = this.state.gridData[activeRow][boundField];
            // получить данные полей и установить состояние для виджета

            // показать новое значение
            this.setState({value: value, fieldValue: fieldValue, show: false});

            // вернуть значение наверх

            if (this.props.onChange) {
                this.props.onChange(boundFieldData, value);

                // text value of input
                if (boundToData) {
                    this.props.onChange(boundToData, fieldValue);
                }

                //если привязано другое поле
                if (this.props.collName) {
                    this.props.onChange(this.props.collName, fieldValue);
                }
            }
        } else {
            // востанавливаем старые значения из пропсов, заврывыаем окно
            this.setState({
                value: this.props.value,
                fieldValue: this.props.defaultValue, show: false
            });
        }
    }

    handleGridClick(event, value, activeRow) {
        this.setState({gridActiveRow: activeRow, value: value});
    }

    loadLibs(fieldValue, kpv) {
        let lib = this.props.libName;
        let sqlWhere = '';
        let limit = this.state.limit ? this.state.limit : 100;
        let isSeachById = (this.state.value && !fieldValue);

        if (this.props.sqlFields && this.props.sqlFields.length && fieldValue && fieldValue.length > 0) {
            this.props.sqlFields.forEach((field) => {
                let isOr = sqlWhere.length > 0 ? ' or ' : '';
                sqlWhere = sqlWhere.concat(` ${isOr} encode(${field}::bytea, 'escape') ilike '%${fieldValue.trim()}%'`);
            });
        }

        if (isSeachById) {
            // will seach by id
            sqlWhere = `id = ${this.state.value}`
        }

        sqlWhere = `where ${sqlWhere}`;

        let libParams = Object.assign({uuid: DocContext.userData.uuid}, sqlWhere.length ? {
            sql: sqlWhere,
            limit: limit,
            kpv: kpv ? kpv: new Date().toISOString().slice(0,10)
        } : {});

        if (sqlWhere.length > 0) {
            fetchData.fetchDataPost(`${POST_LOAD_LIBS_URL}/${lib}`, libParams).then(response => {
                let gridData = [],
                    gridConfig = [];

                if (response && 'data' in response) {
                    gridData = response.data.result.result.data;
                    gridConfig = response.data.result.result.gridConfig;
                }

                if (gridData && gridData.length > 0) {
                    if (isSeachById && !this.state.show) {
                        // только одна запись. Грид не нужен
                        this.setState({
                            fieldValue: gridData[0][this.props.boundToGrid],
                            value: gridData[0]['id'],
                            gridData: gridData,
                            gridConfig: gridConfig
                        });
                    } else {
                       this.setState({gridData: gridData, gridConfig: gridConfig, show: true});
                    }
                }

            }).catch(error => {
                console.error('loadLibs error', error);
            });
        }
    }

    handleGridBtnClick(btnName, activeRow, id, docTypeId) {
        // закрываем модальное окно поиска и переходим на новую запись справочника
        this.setState({show: false});
        let docId = this.state.gridData[activeRow]['id'];
        switch (btnName) {
            case "Muuda":
                this.props.history.push(`/${DocContext.module}/${this.props.libName}/${docId}`);
                break;
            case "edit":
                this.props.history.push(`/${DocContext.module}/${this.props.libName}/${docId}`);
                break;
            case "add":
                this.props.history.push(`/${DocContext.module}/${this.props.libName}/0`);
                break;
            default:
                console.log('Vigane click');
        }
    }


}

SelectData.propTypes = {
    readOnly: PropTypes.bool,
    disabled: PropTypes.bool,
    collId: PropTypes.string,
    title: PropTypes.string,
    placeholder: PropTypes.string,
    name: PropTypes.string.isRequired,
    show: PropTypes.bool
};

SelectData.defaultProps = {
    readOnly: false,
    disabled: false,
    btnDelete: false,
    value: 0,
    collId: 'id',
    title: '',
    show: false
};

module.exports = SelectData;
