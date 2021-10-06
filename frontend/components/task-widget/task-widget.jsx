'use strict';

const PropTypes = require('prop-types');
const getNow = require('./../../../libs/getNow');
const React = require('react'),
    Button = require('../button-register/button-register-execute/button-register-execute.jsx'),
    ButtonOpen = require('../button-register/button-register.jsx'),
    Select = require('../../components/select/select.jsx'),
    InputDate = require('../../components/input-date/input-date.jsx'),
    InputText = require('../../components/input-text/input-text.jsx'),
    InputNumber = require('../../components/input-number/input-number.jsx'),
    ModalPage = require('./../../components/modalpage/modalPage.jsx'),
    styles = require('./task-widget-styles');
const DocContext = require('./../../doc-context.js');


class TaskWidget extends React.PureComponent {
    constructor(props) {
        super(props);
        this.state = {
            taskList: props.taskList || [],
            actualTask: props.taskList[0].name,
            showList: false,
            showModal: false,
            showDate: true,
            titleDate: null,
            showViitenumber: false,
            titleViitenumber: null,
            showYksus: props.kasShowYksus,
            titleYksus: null,
            showKogus: props.kasShowKogus,
            titleKogus: null,
            viitenumber: null,
            yksus: 0,
            kogus: DocContext.mkJaak ? DocContext.mkJaak : 0,
            seisuga: getNow()
        };
        this.handleSelectTask = this.handleSelectTask.bind(this);
        this.handleButtonTask = this.handleButtonTask.bind(this);
        this.handleButtonOpenClick = this.handleButtonOpenClick.bind(this);
        this.modalPageClick = this.modalPageClick.bind(this);
        this.handleInputChange = this.handleInputChange.bind(this);
    }

    render() {
        if (!this.state.taskList) return <div></div>;

        const tasks = this.state.taskList.map((task, index) => {
            return {id: index++, name: ' ', kood: task.name}
        });

        let taskId = tasks.findIndex(task => task.name == this.state.actualTask);

        return (<div style={styles.wrapper}>
                <div>
                    <div style={styles.wrapper}>
                        <Button
                            ref='buttonTask'
                            onClick={this.handleButtonTask}
                            value={this.state.actualTask}
                        />
                        <ButtonOpen
                            ref='buttonOpenList'
                            onClick={this.handleButtonOpenClick}
                            value='v'/>
                    </div>
                    {this.state.showList ?
                        <Select name='name'
                                style={styles.select}
                                data={tasks}
                                collId='kood'
                                value={this.state.actualTask || ''}
                                defaultValue={this.state.actualTask}
                                ref="select-name"
                                onChange={this.handleSelectTask}
                                readOnly={false}/>
                        : null}
                    {this.state.showModal ?
                        <ModalPage
                            modalPageBtnClick={this.modalPageClick}
                            modalPageName={`Tegevus`}
                            show={true}
                            modalObjects={['btnOk', 'btnCancel']}
                        >
                            {`Kas käivata ${this.state.actualTask} ?`}

                            {this.state.showDate ?
                                <InputDate title={this.state.titleDate ? this.state.titleDate : 'Seisuga '}
                                           name='seisuga'
                                           value={this.state.seisuga}
                                           ref='input-kpv'
                                           readOnly={false}
                                           onChange={this.handleInputChange}/> : null}

                            {this.state.showYksus ?
                                <Select title={this.state.titleYksus ? this.state.titleYksus : "Üksus:"}
                                        name='yksus'
                                        libs="lapse_grupp"
                                        data={DocContext.libs.lapse_grupp ? DocContext.libs.lapse_grupp : []}
                                        ref="select-lapse_grupp"
                                        collId={'id'}
                                        onChange={this.handleInputChange}
                                        value={this.state.yksus || 0}
                                        disabled={false}
                                        readOnly={false}
                                /> : null}
                            {this.state.showViitenumber ? <InputText
                                title={this.state.titleViitenumber ? this.state.titleViitenumber : "Viitenumber:"}
                                name='viitenumber'
                                ref="input-viitenumber"
                                onChange={this.handleInputChange}
                                value={this.state.viitenumber}
                                readOnly={false}
                            /> : null}
                            {this.state.showKogus ?
                                <InputNumber title={this.state.titleKogus ? this.state.titleKogus : 'Väärtus'}
                                             name='kogus'
                                             value={Number(this.state.kogus)}
                                             ref='input-kogus'
                                             readOnly={false}
                                             max={(DocContext.mkJaak ? DocContext.mkJaak: 999999999)}
                                             onChange={this.handleInputChange}/> : null}

                        </ModalPage> : null
                    }
                </div>
            </div>

        )
    }

    modalPageClick(btnEvent) {
        this.setState({showModal: false});
        if (btnEvent === 'Ok') {
            this.props.handleButtonTask(this.state.actualTask, this.state.seisuga, this.state.yksus, this.state.viitenumber, this.state.kogus);
        }
    }

    handleButtonOpenClick() {
        let isShow = !this.state.showList;
        this.setState({showList: isShow});
    }

    handleSelectTask(name, value) {
        let isShow = !this.state.showList;
        let task = this.state.taskList.find(task => task.name == value);
        let isShowDate = task && task.hasOwnProperty('hideDate') ? !task.hideDate : true;
        let showYksus = task && task.hasOwnProperty('showYksus') ? task.showYksus : false;
        let showViitenumber = task && task.hasOwnProperty('showViitenumber') ? task.showViitenumber : false;
        let showKogus = task && task.hasOwnProperty('showKogus') ? task.showKogus : false;

        this.setState({
            showList: isShow,
            actualTask: value,
            showDate: isShowDate,
            titleDate: task.titleDate ? task.titleDate : null,
            showYksus: showYksus,
            showViitenumber: showViitenumber,
            titleViitenumber: task.titleViitenumber ? task.titleViitenumber : null,
            showKogus: showKogus,
            titleKogus: task.titleKogus ? task.titleKogus : null
        });
    }

    handleButtonTask() {
        let showYksus = this.state.showYksus;
        let showViitenumber = this.state.showViitenumber;
        let showKogus = this.state.showKogus;
        let task = this.state.taskList.find(task => task.name == this.state.actualTask);
        let isShowDate = task && task.hasOwnProperty('hideDate') ? !task.hideDate : true;
        let isShowViitenumber = task && task.hasOwnProperty('showViitenumber') ? task.showViitenumber : false;
        let isShowKogus = task && task.hasOwnProperty('showKogus') ? task.showKogus : false;

        showYksus = task && task.hasOwnProperty('showYksus') ? task.showYksus : false;

        this.setState({
            showModal: true,
            showYksus: showYksus,
            showDate: isShowDate,
            showKogus: isShowKogus,
            showViitenumber: isShowViitenumber
        });
    }

    //will save value
    handleInputChange(name, value) {
        let stateValue = {
            seisuga: this.state.seisuga,
            yksus: this.state.yksus,
            viitenumber: this.state.viitenumber,
            kogus: this.state.kogus
        };
        stateValue[name] = value;
        this.setState(stateValue);
    }


}

TaskWidget.propTypes = {
    taskList: PropTypes.array,
    handleButtonTask: PropTypes.func.isRequired,
    handleSelectTask: PropTypes.func.isRequired,
    kasShowYksus: PropTypes.bool,
    kasShowKogus: PropTypes.bool,
    kasShowViitenumber: PropTypes.bool
};


TaskWidget.defaultProps = {
    taskList: [],
    kasShowYksus: false,
    kasShowKogus: false,
    kasShowViitenumber: false
};
module.exports = TaskWidget;