use crate::crypto_utils::sha256;
use crate::errors;
use crate::models;

const CANDIDATE_COUNT: i32 = 10;

fn validate_uuid(vote: &models::VoteWeb) -> Result<(), errors::MyError> {
    if vote.uuid.chars().count() != 36 {
        return Result::Err(errors::MyError::ValidationError("Invalid UUID".to_owned()));
    }
    return Result::Ok(());
}

fn validate_nonces(vote: &models::VoteWeb) -> Result<(), errors::MyError> {
    let mut current_string = format!("{}{}", vote.uuid, "czoodle");
    for nonce in &vote.nonces {
        current_string = sha256(&format!("{}{}", current_string, nonce));
        if !current_string.starts_with("777") {
            return Result::Err(errors::MyError::ValidationError(
                "Invalid validation nonce.".to_owned(),
            ));
        }
    }
    return Result::Ok(());
}

fn validate_order(vote: &models::VoteWeb) -> Result<(), errors::MyError> {
    if vote.order.len() as i32 != CANDIDATE_COUNT {
        return Result::Err(errors::MyError::ValidationError(
            "Invalid length of order array.".to_owned(),
        ));
    }
    let mut sorted = vote.order.clone();
    sorted.sort();

    for (index, value) in sorted.into_iter().enumerate() {
        if index as i32 != value {
            return Result::Err(errors::MyError::ValidationError(
                "Invalid order array.".to_owned(),
            ));
        }
    }

    return Result::Ok(());
}

fn validate_two_round_poll(vote: &models::VoteWeb) -> Result<(), errors::MyError> {
    if vote.polls.two_round < 0 || vote.polls.two_round >= CANDIDATE_COUNT {
        return Result::Err(errors::MyError::ValidationError(
            "Invalid two-round poll value.".to_owned(),
        ));
    }
    return Result::Ok(());
}

fn validate_one_round_poll(vote: &models::VoteWeb) -> Result<(), errors::MyError> {
    if vote.polls.one_round < 0 || vote.polls.one_round >= CANDIDATE_COUNT {
        return Result::Err(errors::MyError::ValidationError(
            "Invalid one-round poll value.".to_owned(),
        ));
    }
    return Result::Ok(());
}

fn validate_divide_poll(vote: &models::VoteWeb) -> Result<(), errors::MyError> {
    if vote.polls.divide.len() as i32 != CANDIDATE_COUNT {
        return Result::Err(errors::MyError::ValidationError(
            "Invalid length of divide poll array.".to_owned(),
        ));
    }
    let sum: i32 = vote.polls.divide.iter().sum();
    if sum != 5 {
        return Result::Err(errors::MyError::ValidationError(
            "Invalid divide poll value.".to_owned(),
        ));
    }
    return Result::Ok(());
}

fn validate_d21_poll(vote: &models::VoteWeb) -> Result<(), errors::MyError> {
    if vote.polls.d21.len() as i32 != CANDIDATE_COUNT {
        return Result::Err(errors::MyError::ValidationError(
            "Invalid length of D21 poll array.".to_owned(),
        ));
    }
    let all_valid = vote.polls.d21.iter().all(|&v| v == 0 || v == 1 || v == -1);
    if !all_valid {
        return Result::Err(errors::MyError::ValidationError(
            "Invalid values in D21 poll.".to_owned(),
        ));
    }

    let positive_count = vote.polls.d21.iter().copied().filter(|v| *v > 0).count();

    if positive_count == 0 {
        return Result::Err(errors::MyError::ValidationError(
            "Invalid values in D21 poll - no positive vote.".to_owned(),
        ));
    }

    if positive_count > 3 {
        return Result::Err(errors::MyError::ValidationError(
            "Invalid values in D21 poll - too many positive votes.".to_owned(),
        ));
    }

    let negative_count = vote.polls.d21.iter().copied().filter(|v| *v < 0).count();

    if negative_count > 1 || (positive_count < 2 && negative_count > 0) {
        return Result::Err(errors::MyError::ValidationError(
            "Invalid values in D21 poll - too many negative votes.".to_owned(),
        ));
    }

    return Result::Ok(());
}

fn validate_doodle_poll(vote: &models::VoteWeb) -> Result<(), errors::MyError> {
    if vote.polls.doodle.len() as i32 != CANDIDATE_COUNT {
        return Result::Err(errors::MyError::ValidationError(
            "Invalid length of Doodle poll array.".to_owned(),
        ));
    }

    let all_valid = vote
        .polls
        .doodle
        .iter()
        .all(|&v| v == 0 || v == 1 || v == 2);
    if !all_valid {
        return Result::Err(errors::MyError::ValidationError(
            "Invalid values in Doodle poll.".to_owned(),
        ));
    }

    let positive_count = vote.polls.doodle.iter().copied().filter(|v| *v > 0).count();

    if positive_count == 0 {
        return Result::Err(errors::MyError::ValidationError(
            "Invalid values in Doodle poll - no positive vote".to_owned(),
        ));
    }

    return Result::Ok(());
}

fn validate_order_poll(vote: &models::VoteWeb) -> Result<(), errors::MyError> {
    if vote.polls.order.len() as i32 != CANDIDATE_COUNT {
        return Result::Err(errors::MyError::ValidationError(
            "Invalid length of order poll array.".to_owned(),
        ));
    }
    let mut sorted = vote.polls.order.clone();
    sorted.sort();

    for (index, value) in sorted.into_iter().enumerate() {
        if index as i32 != value {
            return Result::Err(errors::MyError::ValidationError(
                "Invalid order poll.".to_owned(),
            ));
        }
    }
    return Result::Ok(());
}

fn validate_star_poll(vote: &models::VoteWeb) -> Result<(), errors::MyError> {
    if vote.polls.star.len() as i32 != CANDIDATE_COUNT {
        return Result::Err(errors::MyError::ValidationError(
            "Invalid length of star poll array.".to_owned(),
        ));
    }

    let all_valid = vote.polls.star.iter().all(|&v| v >= 0 && v <= 100);
    if !all_valid {
        return Result::Err(errors::MyError::ValidationError(
            "Invalid values in star poll.".to_owned(),
        ));
    }

    let positive_count = vote.polls.star.iter().copied().filter(|v| *v > 0).count();

    if positive_count == 0 {
        return Result::Err(errors::MyError::ValidationError(
            "Invalid values in star poll - no positive vote".to_owned(),
        ));
    }

    return Result::Ok(());
}

pub fn validate_vote(vote: &models::VoteWeb) -> Result<(), errors::MyError> {
    validate_uuid(vote)?;
    validate_nonces(vote)?;
    validate_order(vote)?;
    validate_two_round_poll(vote)?;
    validate_one_round_poll(vote)?;
    validate_divide_poll(vote)?;
    validate_d21_poll(vote)?;
    validate_doodle_poll(vote)?;
    validate_order_poll(vote)?;
    validate_star_poll(vote)?;
    return Result::Ok(());
}
