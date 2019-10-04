'use strict';

const DocContext = require('../../doc-context');

const PropTypes = require('prop-types');
const getDataByFilter = require('../../../libs/getDataByFilter');
const fetchData = require('./../../../libs/fetchData');
const _ = require('lodash');

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
    }

    componentDidMount() {
        if (this.state.value) {
            this.loadLibs('');
        }
    }

    // will update state if props changed
    static getDerivedStateFromProps(nextProps, prevState) {
        if (nextProps.value !== prevState.value && nextProps.defaultValue !== prevState.fieldValue) {
            return {value: nextProps.value, fieldValue: nextProps.defaultValue};
        } else return null;
    }

    render() {
        let isEditeMode = !this.state.readOnly,
            btnStyle = Object.assign({}, styles.button, {display: isEditeMode ? 'inline' : 'none'});

        let inputStyle = Object.assign({}, styles.input,
            this.props.width ? {width: this.props.width} : {},
            this.state.readOnly ? styles.readOnly : {}
        );

        if (this.state.value && !this.state.fieldValue) {
            this.loadLibs()
        }

        return (
            <div style={styles.wrapper}>
                <InputText ref="input"
                           title={this.props.title}
                           name={this.props.name}
                           value={this.state.fieldValue || ''}
                           readOnly={!isEditeMode}
                           onChange={this.handleInputChange}/>

                <Button value='v'
                        ref="btnShow"
                        style={btnStyle}
                        onClick={(e) => this.handleClick(e)}>
                </Button>
                {
                    this.state.show ? this.modalPage() : null
                }
            </div>
        )
    }

    handleClick(e) {
        this.setState({
            show: true
        });
    }

    modalPage() {
        let modalObjects = ['btnOk', 'btnCancel'];
        let limitInputStyle = styles.limitInput;

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
                                   readOnly={false}
                                   onChange={this.handleInputChange}/>
                        <DataGrid gridData={this.state.gridData}
                                  gridColumns={this.state.gridConfig}
                                  onClick={this.handleGridClick}
                                  ref="data-grid"/>
                        <InputText ref="input-limit"
                                   title='Limiit:'
                                   width={limitInputStyle}
                                   name='limit'
                                   value={this.state.limit || 10}
                                   readOnly={false}
                                   onChange={this.handleInputChange}/>
                    </div>
                </ModalPage>);
    }

    // обработчик события измения значения в текстовом (поисковом) поле
    handleInputChange(name, value) {
        this.setState({value: 0, fieldValue: value, show: true});

        if (name == 'gridFilter') {
            // обновим стейт

            if (value.length) {
                //выполним запрос
                setTimeout(() => {
                    this.loadLibs(this.state.fieldValue);
                }, 1000);
            }
        } else {
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
        this.setState({gridActiveRow: activeRow});
    }

    loadLibs(fieldValue) {
        const postUrl = '/newApi/loadLibs';
        let lib = this.props.libName;
        let sqlWhere = '';
        let limit = this.state.limit;
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


        let libParams = Object.assign({uuid: DocContext.userData.uuid}, sqlWhere.length ? {sql: sqlWhere, limit: limit} : {});

        if (sqlWhere.length > 0) {
            fetchData.fetchDataPost(`${postUrl}/${lib}`, libParams).then(response => {
                let gridData = [],
                    gridConfig = [];

                if (response && 'data' in response) {
                    gridData = response.data.result.result.data;
                    gridConfig = response.data.result.result.gridConfig;
                }

                if (_.size(gridData) > 0) {
                    if (isSeachById) {

                        // только одна запись. Грид не нужен
                        this.setState({
                            value: gridData[0]['id'],
                            gridData: gridData,
                            fieldValue: gridData[0][this.props.boundToGrid],
                            gridConfig: gridConfig
                        });
                    } else {
                        this.setState({gridData: gridData, gridConfig: gridConfig});
                    }
                }

            }).catch(error => {
                console.error('loadLibs error', error);
                rejected();
            });
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
