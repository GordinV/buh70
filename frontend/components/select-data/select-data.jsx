'use strict';
//@todo закончить после справочников

const PropTypes = require('prop-types');


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
            gridConfig: [],
            gridActiveRow: 0,
            show: this.props.show
        };
//        this.onChange = this.onChange.bind(this);
        this.handleInputChange = this.handleInputChange.bind(this);
        this.handleGridClick = this.handleGridClick.bind(this);
        this.modalPageClick = this. modalPageClick.bind(this);
        this.testConfiguration = this.testConfiguration.bind(this);
    }

    componentWillReceiveProps(nextProps) {
        this.setState({
            value: nextProps.value,
            fieldValue: nextProps.defaultValue,
            readOnly: nextProps.readOnly,
            show: nextProps.show
        });
    }

    componentDidMount() {
        // запрос
        this.testConfiguration();
    }

/*
        shouldComponentUpdate(nextProps, nextState) {
            // @todo добавить проверку на изменение состояния
            return true;
        }
    */

    render() {
        let isEditeMode = !this.state.readOnly,
            btnStyle = Object.assign({}, styles.button, {display: isEditeMode ? 'inline' : 'none'});

        return (
            <div style={styles.wrapper}>
                <InputText ref="input"
                           title={this.props.title}
                           name={this.props.name}
                           value={this.state.fieldValue}
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
        return (
            <div>
                <ModalPage
                    modalObjects={modalObjects}
                    ref="modalpage-grid"
                    show={true}
                    modalPageBtnClick={this.modalPageClick}
                    modalPageName='Vali rea'>
                    <div ref="grid-row-container">
                        <InputText ref="input-filter"
                                   title='Otsingu parametrid'
                                   name='gridFilter'
                                   value={this.state.fieldValue}
                                   readOnly={false}
                                   onChange={this.handleInputChange}/>
                        <DataGrid gridData={this.state.gridData}
                                  gridColumns={this.state.gridConfig}
                                  onClick = {this.handleGridClick}
                                  ref="data-grid"/>
                    </div>
                </ModalPage>
            </div>);
    }

    handleInputChange(name, value) {
        console.log('handleInputChange', name, value);
    }

    modalPageClick(event) {
        if (event === 'Ok') {
            // надо найти активную строку

            let activeRow = this.state.gridActiveRow,
                value = this.state.gridData[activeRow]['id'],
                fieldValue = this.state.gridData[activeRow]['name'];
            // получить данные полей и установить состояние для виджета

            this.setState({value: value, fieldValue: fieldValue, show: false});

            // вернуть значение наверх
            if (this.props.onChange) {
                this.props.onChange(this.props.name, value);
                //@todo описать
                if (this.props.collName) {
                    this.props.onChange(this.props.collName, fieldValue);
                }
            }

        }
    }

    handleGridClick(event, value, activeRow) {
        this.setState({gridActiveRow: activeRow});
    }

    testConfiguration() {
        let data = [
                {id: 1, type: 'DOK1', name: 'name 1', created: '2017-01-01', lastupdate: '2017-01-01', status: 'ok'},
                {id: 2, type: 'DOK1', name: 'name 2', created: '2017-01-01', lastupdate: '2017-01-01', status: 'ok'},
                {id: 3, type: 'DOK1', name: 'name 3', created: '2017-01-01', lastupdate: '2017-01-01', status: 'ok'},
                {id: 4, type: 'DOK1', name: 'name 4', created: '2017-01-01', lastupdate: '2017-01-01', status: 'ok'},
                {id: 5, type: 'DOK1', name: 'name 5', created: '2017-01-01', lastupdate: '2017-01-01', status: 'ok'},
            ],
            config = [
                {id: "id", name: "id", width: "50px", show: false},
                {id: "type", name: "type", width: "100px"},
                {id: "name", name: "Nimetus", width: "100px"},
                {id: "created", name: "created", width: "150px"},
                {id: "lastupdate", name: "Last change", width: "150px"},
                {id: "status", name: "Status", width: "100px"}
            ];
        this.setState({
            gridConfig: config,
            gridData: data
        });
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
