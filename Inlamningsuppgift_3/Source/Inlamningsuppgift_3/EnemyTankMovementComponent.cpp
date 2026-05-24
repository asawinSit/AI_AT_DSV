#include "EnemyTankMovementComponent.h"
#include "GameFramework/Pawn.h"

UEnemyTankMovementComponent::UEnemyTankMovementComponent()
{
    PrimaryComponentTick.bCanEverTick = true;
}

void UEnemyTankMovementComponent::RequestDirectMove(const FVector& MoveVelocity, bool bForceMaxSpeed)
{
    if (!PawnOwner) return;

    FVector DesiredDir = MoveVelocity.GetSafeNormal();
    if (DesiredDir.IsNearlyZero()) return;

    FRotator CurrentRotation = PawnOwner->GetActorRotation();
    FRotator TargetRotation = DesiredDir.Rotation();

    // Normalize the yaw delta to -180/+180 range to prevent wrap-around spinning
    float CurrentYaw = CurrentRotation.Yaw;
    float TargetYaw = TargetRotation.Yaw;
    float DeltaYaw = FMath::FindDeltaAngleDegrees(CurrentYaw, TargetYaw);

    // Clamp how much we can turn this frame based on TurnSpeed
    float MaxTurnThisFrame = TurnSpeed * GetWorld()->GetDeltaSeconds();
    float ClampedDelta = FMath::Clamp(DeltaYaw, -MaxTurnThisFrame, MaxTurnThisFrame);

    float NewYaw = CurrentYaw + ClampedDelta;

    PawnOwner->SetActorRotation(FRotator(0.0f, NewYaw, 0.0f));

    // Only move along current forward axis
    FVector Forward = PawnOwner->GetActorForwardVector();
    float Dot = FVector::DotProduct(DesiredDir, Forward);

    // Smooth the speed based on alignment - tank slows when turning
    float SpeedScale = FMath::Max(Dot, 0.0f);
    FVector ConstrainedVelocity = Forward * (MoveVelocity.Size() * SpeedScale);

    Super::RequestDirectMove(ConstrainedVelocity, bForceMaxSpeed);
}