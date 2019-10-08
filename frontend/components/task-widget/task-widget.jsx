'use strict';

const PropTypes = require('prop-types');

const React = require('react'),
    Button = require('../button-register/button-register-execute/button-register-execute.jsx'),
    styles = require('./task-widget-styles');

class TaskWidget extends React.PureComponent {
    constructor(props) {
        super(props);
        this.state = {
            taskList: props.taskList || []
        };
        this.handleSelectTask = this.handleSelectTask.bind(this);
        this.handleButtonTask = this.handleButtonTask.bind(this);
    }

    render() {

        if (!this.state.taskList) return <div></div>;

        return (<div style={styles.wrapper}>
                {this.state.taskList.length > 1 ?
                    <select
                        onChange={this.handleSelectTask}
                        show={true}
                        ref='selectTask'>
                        {
                            this.state.taskList.map((taskName, index) => {
                                let key = 'option-' + index;
                                <option value={0} key={key} ref={key}> {taskName.name} </option>
                            })
                        }
                    </select> : <Button
                        ref='buttonTask'
                        onClick={this.handleButtonTask}
                        show={this.state.taskList.length == 1 ? true : false}
                        value={this.state.taskList.length == 1 ? this.state.taskList[0].name : ''}
                    />
                }
            </div>

        )
    }

    handleSelectTask(e) {
        let taskName = e.target.value;
        this.props.handleSelectTask(taskName);
    }

    handleButtonTask() {
        this.props.handleButtonTask();
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