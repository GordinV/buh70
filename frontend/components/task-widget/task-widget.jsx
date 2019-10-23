'use strict';

const PropTypes = require('prop-types');

const React = require('react'),
    Button = require('../button-register/button-register-execute/button-register-execute.jsx'),
    ButtonOpen = require('../button-register/button-register.jsx'),
    Select = require('../../components/select/select.jsx'),
    ModalPage = require('./../../components/modalpage/modalPage.jsx'),

    styles = require('./task-widget-styles');

class TaskWidget extends React.PureComponent {
    constructor(props) {
        super(props);
        this.state = {
            taskList: props.taskList || [],
            actualTask: props.taskList[0].name,
            showList: false,
            showModal: false
        };
        this.handleSelectTask = this.handleSelectTask.bind(this);
        this.handleButtonTask = this.handleButtonTask.bind(this);
        this.handleButtonOpenClick = this.handleButtonOpenClick.bind(this);
        this. modalPageClick =  this.modalPageClick.bind(this);
    }

    render() {
        if (!this.state.taskList) return <div></div>;

        const tasks = this.state.taskList.map((task, index) => {
            return {id: index++, name: task.name}
        });
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
                                readOnly={false}
                                value={this.state.actualTask}
                                collId='name'
                                ref='task_widjet'
                                size={this.state.taskList.length}
                                onChange={this.handleSelectTask}/>
                        : null}
                    {this.state.showModal ?
                        <ModalPage
                            modalPageBtnClick={this.modalPageClick}
                            modalPageName={`Tegevus`}
                            show={true}
                            modalObjects={['btnOk', 'btnCancel']}
                        >
                            {`Kas käivata ${this.state.actualTask} ?`}
                        </ModalPage>: null
                    }
                </div>
            </div>

        )
    }

    modalPageClick(btnEvent) {
        this.setState({showModal: false});
        if (btnEvent === 'Ok') {
            this.props.handleButtonTask(this.state.actualTask);
        }
    }

    handleButtonOpenClick() {
        let isShow = !this.state.showList;
        this.setState({showList: isShow});
    }

    handleSelectTask(name, value) {
        let isShow = !this.state.showList;
        this.setState({showList: isShow, actualTask: value});
    }

    handleButtonTask() {
//        this.props.handleButtonTask(this.state.actualTask);
        this.setState({showModal: true});
    }


}

TaskWidget.propTypes = {
    taskList: PropTypes.array,
    handleButtonTask: PropTypes.func.isRequired,
    handleSelectTask: PropTypes.func.isRequired
};


TaskWidget.defaultProps = {
    taskList: []
};
module.exports = TaskWidget;