import pytest

from app.decision import decide_style, get_config
from app.models import InteractionContext, KnowledgeLevel, Emotion, GoalClarity, Urgency


@pytest.mark.parametrize(
    "context,expected_style",
    [
        (InteractionContext(knowledge=KnowledgeLevel.novice), "explanatory"),
        (InteractionContext(emotion=Emotion.negative), "reassuring_explanatory"),
        (
            InteractionContext(
                knowledge=KnowledgeLevel.expert,
                clarity=GoalClarity.clear,
                urgency=Urgency.normal,
            ),
            "concise",
        ),
        (
            InteractionContext(
                clarity=GoalClarity.ambiguous,
                emotion=Emotion.positive,
                urgency=Urgency.low,
            ),
            "invitational",
        ),
    ],
)
def test_decision_styles(context, expected_style):
    decision = decide_style(context, config=get_config())
    assert decision.style == expected_style