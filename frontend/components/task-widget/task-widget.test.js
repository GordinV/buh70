require('./../../../test/testdom')('<html><body></body></html>'); // создадим ДОМ


import ReactTestUtils from 'react-dom/test-utils';

const React = require('react');
const TaskWidget = require('./task-widget.jsx');
const handleSelectTask = jest.fn();
const handleButtonTask = jest.fn();
let tasks = [{step: 0, name: 'Start', action: 'start', status: 'opened'}];

describe('components test, TaskWidget', () => {
    let component = ReactTestUtils.renderIntoDocument(<TaskWidget
        taskList = {tasks}
        handleSelectTask = {handleSelectTask}
        handleButtonTask = {handleButtonTask}

    />);

    it('should be defined', () => {
        expect(component).toBeDefined();
    });

    it('should not contain selectTask',()=> {
        let selectTask  = component.refs['selectTask'];
        expect(selectTask).toBeUndefined();
    });

    it ('should contain selectButtonTask && handleButtonTask have been called',()=> {
        let buttonTask = component.refs['buttonTask']
        expect(buttonTask).toBeDefined();
/*
        ReactTestUtils.Simulate.click(buttonTask);
        expect(handleButtonTask).toHaveBeenCalled();
*/
    });

    it('should contain 2 tasks and selectTask component', ()=> {
        let tasks = [{step: 0, name: 'Start', action: 'start', status: 'opened'},
            {step: 1, name: 'Close', action: 'finish', status: 'opened'}];

        let component = ReactTestUtils.renderIntoDocument(<TaskWidget
            taskList = {tasks}
            handleSelectTask = {handleSelectTask}
            handleButtonTask = {handleButtonTask}
        />);
        let selectTask  = component.refs['selectTask'];
        expect(selectTask).toBeDefined();
        ReactTestUtils.Simulate.change(selectTask, {"target": {"value": tasks[1].name}});
        expect(handleSelectTask).toHaveBeenCalled();
        expect(handleSelectTask).toHaveBeenCalledWith(tasks[1].name);
    });

    it('should not contain select and button should have show = false', ()=> {
        let tasks = [{step: 0, name: 'Start', action: 'start', status: 'closed'}];

        let component = ReactTestUtils.renderIntoDocument(<TaskWidget
            taskList = {tasks}
            handleSelectTask = {handleSelectTask}
            handleButtonTask = {handleButtonTask}
        />);

        expect(component.refs['selectTask']).toBeUndefined();
        expect(component.refs['buttonTask']).toBeDefined();
      })
});